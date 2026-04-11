import cv2
import numpy as np
from pathlib import Path
from PIL import Image
from ultralytics import YOLO
import joblib
import warnings
from collections import Counter
import time

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
CRIME_CONFIDENCE_THRESHOLD = 0.3


class CrimeModelInference:
    """Pose estimation (ONNX) + Crime classification for behavioral crimes"""
    
    def __init__(self, pose_model_onnx_path, brain_model_path):
        """Initialize ONNX pose detector and crime classifier"""
        try:
            self.pose_model = YOLO(pose_model_onnx_path)  # Load ONNX model
            print(f"✓ Pose ONNX model loaded: {pose_model_onnx_path}")
        except Exception as e:
            raise Exception(f"Failed to load ONNX pose model: {str(e)}")
        
        try:
            self.brain_model = joblib.load(brain_model_path)
            print(f"✓ Crime brain model loaded from: {brain_model_path}")
        except Exception as e:
            print(f"⚠ Warning: Crime brain model failed to load: {str(e)}")
            self.brain_model = None
    
    def _extract_skeleton_features(self, frame):
        """Extract skeleton keypoints from frame using ONNX pose model"""
        try:
            results = self.pose_model.predict(frame, conf=0.5, verbose=False)
            
            if len(results) == 0:
                return []
            
            result = results[0]
            
            if result.keypoints is None or len(result.keypoints) == 0:
                return []
            
            # Get normalized keypoint coordinates (already normalized to 0-1)
            all_skeletons = result.keypoints.xyn.cpu().numpy()
            return all_skeletons
        except Exception as e:
            return []
    
    def _classify_crime_action(self, skeleton):
        """Classify crime action from skeleton keypoints using Random Forest Brain"""
        if self.brain_model is None:
            return None
        
        try:
            # Flatten skeleton into feature vector for Random Forest
            flat_skeleton = skeleton.flatten().reshape(1, -1)
            
            # Check for zero skeleton (invalid pose)
            if np.all(flat_skeleton == 0):
                return None
            
            # Predict crime action
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                prediction = self.brain_model.predict(flat_skeleton)
            
            crime_label = str(prediction[0]).strip("[]'\"")
            
            return {
                "crime_action": crime_label,
                "model": "crime_brain",
                "is_normal": crime_label.lower() == "normal"
            }
        except Exception as e:
            return None
    
    def detect_crime_from_image(self, image_path):
        """Detect crime behavior from IMAGE"""
        try:
            frame = cv2.imread(image_path)
            if frame is None:
                return None
            
            skeletons = self._extract_skeleton_features(frame)
            if not skeletons:
                return None
            
            # Get best detection (first skeleton)
            skeleton = skeletons[0]
            return self._classify_crime_action(skeleton)
        except Exception as e:
            return None
    
    def detect_crime_from_video(self, video_path):
        """Detect crime from VIDEO using every 3rd frame approach (WORKING MODEL LOGIC)"""
        try:
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                return None
            
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            frame_skip = 3  # Process every 3rd frame
            frame_count = 0
            all_predictions = []  # Collect ALL predictions
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
                frame_count += 1
                
                # Only process every 3rd frame (like working model)
                if frame_count % frame_skip == 1:
                    skeletons = self._extract_skeleton_features(frame)
                    
                    if not skeletons:
                        continue
                    
                    # Process ALL skeletons in this frame
                    for skeleton in skeletons:
                        flat_skeleton = skeleton.flatten().reshape(1, -1)
                        
                        # Check for zero skeleton (invalid pose)
                        if np.all(flat_skeleton == 0):
                            continue
                        
                        # Predict crime action
                        try:
                            with warnings.catch_warnings():
                                warnings.simplefilter("ignore")
                                prediction = self.brain_model.predict(flat_skeleton)
                            
                            # Clean output string
                            crime_label = str(prediction[0]).replace("[", "").replace("]", "").replace("'", "").strip()
                            all_predictions.append(crime_label)
                        except Exception as e:
                            continue
            
            cap.release()
            
            # Apply working model's final logic
            if not all_predictions:
                return None
            
            # Filter out "Normal" frames
            crimes_only = [p for p in all_predictions if p != "Normal"]
            
            if not crimes_only:
                # All predictions were Normal
                return {
                    "crime_action": "Normal",
                    "is_normal": True,
                    "confidence": 0.0
                }
            
            # Get the MOST COMMON crime (like working model)
            top_crime, frequency = Counter(crimes_only).most_common(1)[0]
            confidence = frequency / len(crimes_only)  # Frequency as confidence
            
            return {
                "crime_action": top_crime,
                "is_normal": False,
                "confidence": confidence,
                "prediction_count": len(all_predictions),
                "crime_count": len(crimes_only)
            }
        except Exception as e:
            print(f"Error in detect_crime_from_video: {str(e)}")
            return None
    
    def detect_crime_from_frames(self, frame_paths):
        """Detect crime from VIDEO frames - returns all detections"""
        all_crimes = []
        
        for frame_path in frame_paths:
            try:
                frame = cv2.imread(frame_path)
                if frame is None:
                    continue
                
                skeletons = self._extract_skeleton_features(frame)
                if not skeletons:
                    continue
                
                # Process all detected skeletons in this frame
                for skeleton in skeletons:
                    crime_result = self._classify_crime_action(skeleton)
                    if crime_result:
                        all_crimes.append(crime_result)
            except Exception as e:
                continue
        
        return all_crimes

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
    """Orchestrates 7Classes, Weapons, and Crime models"""
    
    def __init__(self, yolo_model_path, weapons_model_path, pose_model_onnx_path, brain_model_path):
        """Initialize all three models"""
        try:
            # Load 7Classes YOLO model
            self.yolo_model = YOLO(yolo_model_path)
            print(f"✓ YOLO 7Classes model loaded from: {yolo_model_path}")
        except Exception as e:
            raise Exception(f"Failed to load YOLO model: {str(e)}")
        
        try:
            # Load Weapons ONNX model
            self.weapons_model = YOLO(weapons_model_path)
            print(f"✓ Weapons ONNX model loaded from: {weapons_model_path}")
        except Exception as e:
            print(f"⚠ Warning: Weapons model failed to load: {str(e)}")
            self.weapons_model = None
        
        try:
            # Load Crime Model (Pose + Brain)
            self.crime_model = CrimeModelInference(pose_model_onnx_path, brain_model_path)
            print(f"✓ Crime detection system initialized")
        except Exception as e:
            print(f"⚠ Warning: Crime model failed to load: {str(e)}")
            self.crime_model = None
    
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
        Run all three models with priority system:
        1. CRIME MODEL: Behavioral crimes (filter out Normal)
        2. WEAPONS: Firearm/Cold Weapon (high priority when detected)
        3. 7CLASSES: Environmental incidents (filter out Normal)
        
        Returns best detection or {"no_incident": True}
        """
        try:
            best_crime_result = None
            best_weapons_result = None
            best_yolo_result = None
            highest_weapon_confidence = 0
            highest_yolo_confidence = 0
            
            # === CRIME MODEL (Highest Priority) ===
            if self.crime_model:
                try:
                    if media_type == "VIDEO":
                        # For video: process every 3rd frame and aggregate predictions
                        crime_result = self.crime_model.detect_crime_from_video(media_path)
                    else:
                        # For image: single prediction
                        crime_result = self.crime_model.detect_crime_from_image(media_path)
                    
                    if crime_result and not crime_result.get("is_normal", False):
                        best_crime_result = crime_result
                except Exception as e:
                    print(f"Crime model error: {str(e)}")
            
            # === WEAPONS MODEL (Second Priority) ===
            if media_type == "VIDEO":
                # Extract one frame for weapons detection
                cap = cv2.VideoCapture(media_path)
                ret, frame = cap.read()
                cap.release()
                if ret:
                    temp_frame_path = media_path.replace(".mp4", "_weapon_test.jpg").replace(".avi", "_weapon_test.jpg")
                    cv2.imwrite(temp_frame_path, frame)
                    weapons_result = self._run_weapons_detection(temp_frame_path)
                    Path(temp_frame_path).unlink(missing_ok=True)
                    if weapons_result and weapons_result['confidence'] > highest_weapon_confidence:
                        best_weapons_result = weapons_result
                        highest_weapon_confidence = weapons_result['confidence']
            else:
                weapons_result = self._run_weapons_detection(media_path)
                if weapons_result and weapons_result['confidence'] > highest_weapon_confidence:
                    best_weapons_result = weapons_result
                    highest_weapon_confidence = weapons_result['confidence']
            
            # === 7CLASSES MODEL (Third Priority) ===
            if media_type == "VIDEO":
                # Extract one frame for 7classes detection
                cap = cv2.VideoCapture(media_path)
                ret, frame = cap.read()
                cap.release()
                if ret:
                    temp_frame_path = media_path.replace(".mp4", "_7class_test.jpg").replace(".avi", "_7class_test.jpg")
                    cv2.imwrite(temp_frame_path, frame)
                    yolo_result = self._run_7classes_detection(temp_frame_path)
                    Path(temp_frame_path).unlink(missing_ok=True)
                    if yolo_result['confidence'] > highest_yolo_confidence:
                        best_yolo_result = yolo_result
                        highest_yolo_confidence = yolo_result['confidence']
            else:
                yolo_result = self._run_7classes_detection(media_path)
                if yolo_result['confidence'] > highest_yolo_confidence:
                    best_yolo_result = yolo_result
                    highest_yolo_confidence = yolo_result['confidence']
            
            # === DECISION LOGIC: Priority-based response ===
            
            # 1. If crime detected (non-Normal), return it
            if best_crime_result:
                crime_class = best_crime_result.get("crime_action", "Unknown").lower()
                return {
                    "incident_type": crime_class,
                    "confidence": best_crime_result.get("confidence", 0.0),
                    "model": "crime",
                    "details": f"Analyzed {best_crime_result.get('prediction_count', 0)} keyframes"
                }
            
            # 2. If weapon detected, return it
            if best_weapons_result:
                return best_weapons_result
            
            # 3. If 7Classes detected (and not Normal), return it
            if best_yolo_result and best_yolo_result['class_name'] != 'Normal':
                return best_yolo_result
            
            # 4. No valid incident detected
            return {
                "no_incident": True,
                "reason": "All models classified as Normal or no detection"
            }
        
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
