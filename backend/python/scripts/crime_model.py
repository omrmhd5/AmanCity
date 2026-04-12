import cv2
import numpy as np
import joblib
import warnings
from pathlib import Path
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
        """Detect crime from single image - checks ALL skeletons"""
        try:
            frame = cv2.imread(image_path)
            if frame is None:
                return None
            
            skeletons = self._extract_skeleton_features(frame)
            if len(skeletons) == 0:
                return None
            
            # Check ALL skeletons, return best detection
            best_detection = None
            highest_confidence = 0
            
            for skeleton in skeletons:
                detection = self._classify_crime_action(skeleton)
                if detection and detection['confidence'] >= 0.5:
                    # Prefer non-Normal detections
                    if not detection.get("is_normal", False):
                        if detection['confidence'] > highest_confidence:
                            highest_confidence = detection['confidence']
                            best_detection = detection
                    elif best_detection is None:  # Use Normal as fallback if no crime found
                        best_detection = detection
            
            return best_detection
        except Exception as e:
            return None
    
    def _extract_key_frames(self, video_path, total_frames):
        """Extract key frames from video - evenly distributed based on video length"""
        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        video_seconds = total_frames / fps if fps > 0 else 10
        
        # Adaptive frame extraction based on video length
        if video_seconds <= 10:
            num_frames = 10
            consensus_required = 2
        elif video_seconds <= 30:
            num_frames = 15
            consensus_required = 3
        else:
            num_frames = 15
            consensus_required = 3
        
        print(f"  Video duration: {video_seconds:.1f}s → Extracting {num_frames} frames, consensus={consensus_required}")
        
        if total_frames == 0:
            cap.release()
            return [], num_frames, consensus_required
        
        # Calculate frame indices to sample (evenly distributed)
        frame_indices = [int(i * total_frames / num_frames) for i in range(num_frames)]
        frame_paths = []
        
        for idx, frame_num in enumerate(frame_indices):
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_num)
            ret, frame = cap.read()
            
            if ret:
                temp_frame_path = video_path.replace(".mp4", f"_crime_{idx}.jpg").replace(".avi", f"_crime_{idx}.jpg")
                cv2.imwrite(temp_frame_path, frame)
                frame_paths.append(temp_frame_path)
        
        cap.release()
        return frame_paths, num_frames, consensus_required
    
    def detect_from_video(self, video_path):
        """Detect crime from video - extract 10 key frames with consensus voting"""
        try:
            if self.brain_model is None:
                print("❌ Brain model not loaded!")
                return None
            
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                print(f"❌ Could not open video: {video_path}")
                return None
            
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            cap.release()
            
            print(f"🎬 Processing video: {video_path} ({total_frames} total frames)")
            
            # Extract frames with adaptive settings
            frame_paths, num_frames, consensus_required = self._extract_key_frames(video_path, total_frames)
            
            if len(frame_paths) == 0:
                print("⚠️  Could not extract frames from video")
                return None
            
            best_crime_result = None
            highest_confidence = 0
            all_detections = []
            
            # Process each key frame
            for frame_path in frame_paths:
                try:
                    result = self.detect_from_image(frame_path)
                    if result and not result.get("is_normal", False):  # Only count non-Normal crimes
                        all_detections.append(result)
                        print(f"  Detected: {result['crime_action']} (conf={result['confidence']:.2f})")
                        
                        # Track best detection
                        if result['confidence'] > highest_confidence:
                            highest_confidence = result['confidence']
                            best_crime_result = result
                except Exception as e:
                    continue
            
            # Clean up temp frames
            for frame_path in frame_paths:
                Path(frame_path).unlink(missing_ok=True)
            
            print(f"📊 Total crime detections: {len(all_detections)} out of {num_frames} frames")
            
            # Consensus voting: require detection in at least required frames
            if len(all_detections) < consensus_required:
                print("⚠️  Crime consensus not met (detected in < 2 frames)")
                return {
                    "crime_action": "Normal",
                    "is_normal": True,
                    "confidence": 0.0
                }
            
            if not best_crime_result:
                print("⚠️  No crimes detected in video")
                return {
                    "crime_action": "Normal",
                    "is_normal": True,
                    "confidence": 0.0
                }
            
            print(f"🎯 FINAL VERDICT: {best_crime_result['crime_action'].upper()} DETECTED (conf={best_crime_result['confidence']:.2f}, consensus={len(all_detections)}/{consensus_required})")
            
            return {
                "crime_action": best_crime_result['crime_action'],
                "is_normal": False,
                "confidence": best_crime_result['confidence'],
                "model": "crime_brain"
            }
        except Exception as e:
            print(f"❌ Error in detect_crime_from_video: {str(e)}")
            import traceback
            traceback.print_exc()
            return None
