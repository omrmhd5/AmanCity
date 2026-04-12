import cv2
import numpy as np
import joblib
import warnings
from collections import Counter
from ultralytics import YOLO


class CrimeModelInference:
    """Pose estimation (.pt) + Crime classification for behavioral crimes"""
    
    def __init__(self, pose_model_pt_path, brain_model_path):
        """Initialize pose detector and crime classifier"""
        try:
            self.pose_model = YOLO(pose_model_pt_path)
            print(f"✓ Pose .pt model loaded: {pose_model_pt_path}")
        except Exception as e:
            raise Exception(f"Failed to load pose model: {str(e)}")
        
        try:
            self.brain_model = joblib.load(brain_model_path)
            print(f"✓ Crime brain model loaded from: {brain_model_path}")
        except Exception as e:
            print(f"⚠ Warning: Crime brain model failed to load: {str(e)}")
            self.brain_model = None
    
    def _extract_skeleton_features(self, frame):
        """Extract skeleton keypoints from frame"""
        try:
            results = self.pose_model.predict(frame, conf=0.5, verbose=False)
            
            if len(results) == 0:
                return []
            
            result = results[0]
            
            if result.keypoints is None or len(result.keypoints) == 0:
                return []
            
            all_skeletons = result.keypoints.xyn.cpu().numpy()
            return all_skeletons
        except Exception as e:
            return []
    
    def _classify_crime_action(self, skeleton):
        """Classify crime action using RandomForest brain model"""
        if self.brain_model is None:
            return None
        
        try:
            flat_skeleton = skeleton.flatten().reshape(1, -1)
            
            if np.all(flat_skeleton == 0):
                return None
            
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                probabilities = self.brain_model.predict_proba(flat_skeleton)
                prediction = self.brain_model.predict(flat_skeleton)
            
            crime_label = str(prediction[0]).strip("[]'\"")
            
            # Get confidence from probabilities
            max_prob = float(np.max(probabilities))
            
            return {
                "crime_action": crime_label,
                "model": "crime_brain",
                "confidence": max_prob,
                "is_normal": crime_label.lower() == "normal"
            }
        except Exception as e:
            return None
    
    def detect_from_image(self, image_path):
        """Detect crime from single image"""
        try:
            frame = cv2.imread(image_path)
            if frame is None:
                return None
            
            skeletons = self._extract_skeleton_features(frame)
            if not skeletons:
                return None
            
            skeleton = skeletons[0]
            return self._classify_crime_action(skeleton)
        except Exception as e:
            return None
    
    def detect_from_video(self, video_path):
        """Detect crime from video - processes every 3rd frame"""
        try:
            if self.brain_model is None:
                print("❌ Brain model not loaded!")
                return None
            
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                print(f"❌ Could not open video: {video_path}")
                return None
            
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            frame_skip = 3
            frame_count = 0
            frames_processed = 0  # Track actual frames processed
            all_predictions = []  # Store (frame_num, crime_label) tuples
            frame_predictions = {}  # Track predictions per frame
            
            print(f"🎬 Processing video: {video_path} ({total_frames} total frames)")
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
                frame_count += 1
                
                if frame_count % frame_skip == 1:
                    frames_processed += 1  # Increment frames processed
                    frame_predictions[frame_count] = []  # Track predictions for this frame
                    results = self.pose_model.predict(frame, conf=0.5, verbose=False, stream=True)
                    
                    for r in results:
                        if r.keypoints is not None and len(r.keypoints) > 0:
                            all_skeletons = r.keypoints.xyn.cpu().numpy()
                            
                            for skeleton in all_skeletons:
                                flat_skeleton = skeleton.flatten().reshape(1, -1)
                                
                                if np.all(flat_skeleton == 0):
                                    continue
                                
                                try:
                                    with warnings.catch_warnings():
                                        warnings.simplefilter("ignore")
                                        probabilities = self.brain_model.predict_proba(flat_skeleton)
                                        prediction = self.brain_model.predict(flat_skeleton)
                                    
                                    crime_label = str(prediction[0]).replace("[", "").replace("]", "").replace("'", "").strip()
                                    # Get confidence from probabilities
                                    confidence = float(np.max(probabilities))
                                    
                                    # Only store if confidence >= 0.5
                                    if confidence >= 0.5:
                                        all_predictions.append((frame_count, crime_label, confidence))
                                        frame_predictions[frame_count].append(crime_label)
                                        print(f"  Frame {frame_count}: {crime_label} (conf={confidence:.2f})")
                                except Exception as e:
                                    continue
            
            cap.release()
            
            print(f"📊 Total predictions collected: {len(all_predictions)}")
            
            if not all_predictions:
                print("⚠️  No humans detected in video")
                return None
            
            # Extract just the labels, excluding Normal
            crimes_only = [label for frame, label, conf in all_predictions if label != "Normal"]
            
            print(f"🔍 Crimes found: {len(crimes_only)} out of {len(all_predictions)}")
            
            if not crimes_only:
                print("✓ No crimes detected - all frames were Normal")
                return {
                    "crime_action": "Normal",
                    "is_normal": True,
                    "confidence": 0.0
                }
            
            # Find the most common crime
            top_crime, _ = Counter(crimes_only).most_common(1)[0]
            
            # Calculate average confidence from all detections for top crime
            crime_confidences = []
            for frame_num, label, conf in all_predictions:
                if label == top_crime:
                    crime_confidences.append(conf)
            
            confidence = sum(crime_confidences) / len(crime_confidences) if crime_confidences else 0.0
            
            print(f"🎯 FINAL VERDICT: {top_crime.upper()} DETECTED ({len(crime_confidences)} detections, conf={confidence:.2f})")
            
            return {
                "crime_action": top_crime,
                "is_normal": False,
                "confidence": confidence,
                "prediction_count": len(all_predictions),
                "crime_count": len(crimes_only)
            }
        except Exception as e:
            print(f"❌ Error in detect_crime_from_video: {str(e)}")
            import traceback
            traceback.print_exc()
            return None
