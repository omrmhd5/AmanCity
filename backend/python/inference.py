import cv2
import numpy as np
from pathlib import Path
from PIL import Image
from ultralytics import YOLO

# Class mapping from your YOLO model
CLASS_NAMES = {
    0: "Accident",
    1: "Damaged Building",
    2: "Fire",
    3: "Flood",
    4: "Normal",
    5: "Public Issue",
    6: "Road Damage",
    7: "Firearm",  # ONNX weapon detector class 0
    8: "Cold Weapon",  # ONNX weapon detector class 1
}

# Weapon confidence threshold
WEAPON_CONFIDENCE_THRESHOLD = 0.5

class YOLOInference:
    def __init__(self, model_path):
        """Initialize YOLO model using ultralytics"""
        try:
            self.model = YOLO(model_path)
            print(f"✓ Model loaded from: {model_path}")
        except Exception as e:
            raise Exception(f"Failed to load YOLO model: {str(e)}")

    def extract_frame_from_video(self, video_path):
        """Extract first frame from video for inference"""
        cap = cv2.VideoCapture(video_path)
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            raise Exception("Failed to extract frame from video")
        
        # Save temp frame
        temp_frame_path = video_path.replace(".mp4", ".jpg").replace(".avi", ".jpg")
        cv2.imwrite(temp_frame_path, frame)
        return temp_frame_path

    def predict(self, image_path):
        """Run inference on image"""
        try:
            # Run YOLO inference
            results = self.model(image_path)
            
            if len(results) == 0:
                raise Exception("No results from YOLO inference")
            
            result = results[0]
            
            # Get the class with highest confidence
            if hasattr(result, 'probs') and result.probs is not None:
                # Classification mode
                class_id = int(result.probs.top1)
                confidence = float(result.probs.top1conf)
            elif hasattr(result, 'boxes') and len(result.boxes) > 0:
                # Detection mode - get highest confidence box
                confidences = result.boxes.conf.cpu().numpy()
                class_ids = result.boxes.cls.cpu().numpy().astype(int)
                max_idx = np.argmax(confidences)
                class_id = class_ids[max_idx]
                confidence = float(confidences[max_idx])
            else:
                raise Exception("Could not extract predictions from YOLO output")
            
            class_name = CLASS_NAMES.get(class_id, "Unknown")
            
            return {
                "class_id": class_id,
                "class_name": class_name,
                "confidence": confidence,
            }
        except Exception as e:
            raise Exception(f"Inference failed: {str(e)}")

    def predict_from_media(self, media_path, media_type):
        """
        Predict from image or video
        media_type: "IMAGE" or "VIDEO"
        """
        try:
            if media_type == "VIDEO":
                frame_path = self.extract_frame_from_video(media_path)
                result = self.predict(frame_path)
                # Clean up temp frame
                Path(frame_path).unlink(missing_ok=True)
                return result
            else:  # IMAGE
                return self.predict(media_path)
        except Exception as e:
            raise Exception(f"Prediction failed: {str(e)}")


class DualModelInference:
    """Orchestrates both 7Classes and Weapons models with conditional response logic"""
    
    def __init__(self, yolo_model_path, weapons_model_path):
        """Initialize both models"""
        try:
            # Load 7Classes YOLO model
            self.yolo_model = YOLO(yolo_model_path)
            print(f"✓ YOLO 7Classes model loaded from: {yolo_model_path}")
        except Exception as e:
            raise Exception(f"Failed to load YOLO model: {str(e)}")
        
        try:
            # Load Weapons ONNX model using YOLO (automatically detects .onnx extension)
            self.weapons_model = YOLO(weapons_model_path)
            print(f"✓ Weapons ONNX model loaded from: {weapons_model_path}")
        except Exception as e:
            print(f"⚠ Warning: Weapons model failed to load: {str(e)}")
            self.weapons_model = None
    
    def _run_weapons_detection(self, image_path):
        """Run weapons detection with YOLO ONNX model
        ONNX model outputs 2 classes:
        - 0: Firearm (maps to CLASS_NAMES[7])
        - 1: Cold Weapon (maps to CLASS_NAMES[8])
        """
        if self.weapons_model is None:
            return None
        
        try:
            # Run YOLO inference on weapons model
            results = self.weapons_model.predict(image_path, conf=0.0, verbose=False)
            
            if len(results) == 0:
                return None
            
            result = results[0]
            
            # Check if any weapon detected with confidence >= 50%
            if len(result.boxes) > 0:
                # Get the highest confidence detection
                confidences = result.boxes.conf.cpu().numpy()
                class_ids = result.boxes.cls.cpu().numpy().astype(int)
                max_idx = np.argmax(confidences)
                max_confidence = float(confidences[max_idx])
                onnx_class_id = int(class_ids[max_idx])
                
                # If any detection >= 50%, report as weapon
                if max_confidence >= WEAPON_CONFIDENCE_THRESHOLD:
                    # Map ONNX output (0 or 1) to CLASS_NAMES indices (7 or 8)
                    class_id = 7 + onnx_class_id  # 0 -> 7 (Firearm), 1 -> 8 (Cold Weapon)
                    class_name = CLASS_NAMES.get(class_id, "Unknown")
                    
                    return {
                        "class_id": class_id,
                        "class_name": class_name,
                        "confidence": max(0.0, min(1.0, max_confidence)),
                        "model": "weapons"
                    }
            
            return None
        except Exception as e:
            print(f"⚠ Weapons detection error: {str(e)}")
            return None
    
    def _run_7classes_detection(self, image_path):
        """Run 7Classes YOLO detection"""
        try:
            results = self.yolo_model(image_path)
            
            if len(results) == 0:
                raise Exception("No results from YOLO inference")
            
            result = results[0]
            
            # Get the class with highest confidence
            if hasattr(result, 'probs') and result.probs is not None:
                class_id = int(result.probs.top1)
                confidence = float(result.probs.top1conf)
            elif hasattr(result, 'boxes') and len(result.boxes) > 0:
                confidences = result.boxes.conf.cpu().numpy()
                class_ids = result.boxes.cls.cpu().numpy().astype(int)
                max_idx = np.argmax(confidences)
                class_id = class_ids[max_idx]
                confidence = float(confidences[max_idx])
            else:
                raise Exception("Could not extract predictions from YOLO output")
            
            class_name = CLASS_NAMES.get(class_id, "Unknown")
            
            return {
                "class_id": class_id,
                "class_name": class_name,
                "confidence": float(confidence),
                "model": "7Classes"
            }
        except Exception as e:
            raise Exception(f"7Classes inference failed: {str(e)}")
    
    def predict_from_media(self, media_path, media_type):
        """
        Run both models and return conditional response:
        - If Normal detected: return no_incident flag
        - If weapon detected: return both outputs (user chooses)
        - Otherwise: return only 7Classes output
        """
        try:
            # Extract frames if video (sample multiple frames)
            if media_type == "VIDEO":
                frame_paths = self._extract_frames_from_video(media_path)
            else:
                frame_paths = [media_path]
            
            best_weapons_result = None
            best_yolo_result = None
            highest_weapon_confidence = 0
            highest_yolo_confidence = 0
            
            # Process each frame: EXECUTION ORDER = 7Classes FIRST, then Weapons
            for frame_path in frame_paths:
                yolo_result = self._run_7classes_detection(frame_path)  # RUN FIRST
                weapons_result = self._run_weapons_detection(frame_path)  # RUN SECOND
                
                # Track best 7Classes detection (highest confidence)
                if yolo_result['confidence'] > highest_yolo_confidence:
                    best_yolo_result = yolo_result
                    highest_yolo_confidence = yolo_result['confidence']
                
                # Track best weapons detection (highest confidence)
                if weapons_result and weapons_result['confidence'] > highest_weapon_confidence:
                    best_weapons_result = weapons_result
                    highest_weapon_confidence = weapons_result['confidence']
            
            # Clean up temp frames if video
            if media_type == "VIDEO":
                for frame_path in frame_paths:
                    Path(frame_path).unlink(missing_ok=True)
            
            # Determine response: WEAPONS FIRST (don't block with Normal)
            if best_weapons_result:
                # If alternative is "Normal", don't show it - user choice unnecessary
                if best_yolo_result and best_yolo_result['class_name'] == 'Normal':
                    return best_weapons_result
                else:
                    # Alternative is not Normal - show both for user to choose
                    return {
                        "dual_prediction": True,
                        "primary": best_weapons_result,
                        "alternative": best_yolo_result,
                        "decision": "user_choice"
                    }
            
            # Check if primary result is Normal - only block if no weapon detected
            if best_yolo_result['class_name'] == 'Normal':
                return {
                    "no_incident": True,
                    "reason": "Image classified as Normal - no incident detected"
                }
            else:
                # No weapon detected, return only 7Classes
                return best_yolo_result
        
        except Exception as e:
            raise Exception(f"Prediction failed: {str(e)}")
    
    def _extract_frames_from_video(self, video_path, num_frames=5):
        """Extract multiple frames from video for inference"""
        cap = cv2.VideoCapture(video_path)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        if total_frames == 0:
            cap.release()
            raise Exception("Failed to read video frames")
        
        # Calculate frame indices to sample (evenly distributed)
        frame_indices = [int(i * total_frames / num_frames) for i in range(num_frames)]
        frame_paths = []
        
        for idx, frame_num in enumerate(frame_indices):
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_num)
            ret, frame = cap.read()
            
            if ret:
                temp_frame_path = video_path.replace(".mp4", f"_frame_{idx}.jpg").replace(".avi", f"_frame_{idx}.jpg")
                cv2.imwrite(temp_frame_path, frame)
                frame_paths.append(temp_frame_path)
        
        cap.release()
        
        if not frame_paths:
            raise Exception("Failed to extract frames from video")
        
        return frame_paths
