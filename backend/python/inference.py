import cv2
import numpy as np
from pathlib import Path
from PIL import Image
from ultralytics import YOLO

# Class mapping from your YOLO model
CLASS_NAMES = {
    0: "Accident",
    1: "Damaged_Building",
    2: "Fire",
    3: "Flood",
    4: "Normal",
    5: "Public_Issue",
    6: "Road_Damage",
    7: "Weapon",  # New weapon class
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
        """Run weapons detection with YOLO ONNX model"""
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
                max_confidence = float(np.max(confidences))
                
                # If any detection >= 50%, report as weapon
                if max_confidence >= WEAPON_CONFIDENCE_THRESHOLD:
                    print(f"🔍 Weapon detected! Highest confidence: {max_confidence:.2%}")
                    return {
                        "class_id": 7,
                        "class_name": "Weapon",
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
        - If weapon detected: return both outputs (user chooses)
        - If no weapon: return only 7Classes output
        """
        try:
            # Extract frame if video
            if media_type == "VIDEO":
                frame_path = self._extract_frame_from_video(media_path)
            else:
                frame_path = media_path
            
            # Always run both models
            yolo_result = self._run_7classes_detection(frame_path)
            weapons_result = self._run_weapons_detection(frame_path)
            
            # Clean up temp frame if video
            if media_type == "VIDEO":
                Path(frame_path).unlink(missing_ok=True)
            
            # Determine response: if weapon detected, return both
            if weapons_result:
                
                print(f"🔍 Weapon detected (confidence: {weapons_result['confidence']:.2%})")
                return {
                    "dual_prediction": True,
                    "primary": weapons_result,
                    "alternative": yolo_result,
                    "decision": "user_choice"
                }
            else:
                # No weapon detected, return only 7Classes
                print(f"✓ Normal incident: {yolo_result['class_name']}")
                return yolo_result
        
        except Exception as e:
            raise Exception(f"Prediction failed: {str(e)}")
    
    def _extract_frame_from_video(self, video_path):
        """Extract first frame from video for inference"""
        cap = cv2.VideoCapture(video_path)
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            raise Exception("Failed to extract frame from video")
        
        temp_frame_path = video_path.replace(".mp4", ".jpg").replace(".avi", ".jpg")
        cv2.imwrite(temp_frame_path, frame)
        return temp_frame_path
