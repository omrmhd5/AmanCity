import cv2
import numpy as np
import warnings
from ultralytics import YOLO
from collections import Counter
from pathlib import Path

# Suppress YOLO task warnings
warnings.filterwarnings('ignore', category=UserWarning, module='ultralytics')

CLASS_NAMES = {
    0: "Accident",
    1: "Damaged Building",
    2: "Fire",
    3: "Flood",
    4: "Normal",
    5: "Public Issue",
    6: "Road Damage",
}


class YOLOSevenClassesInference:
    """7Classes environmental incident detection"""
    
    def __init__(self, model_path):
        """Initialize 7Classes YOLO model"""
        try:
            self.model = YOLO(model_path)
            print(f"✓ YOLO 7Classes model loaded from: {model_path}")
        except Exception as e:
            raise Exception(f"Failed to load YOLO model: {str(e)}")
    
    def detect_from_image(self, image_path):
        """Detect 7Classes from image - filters out Normal and low confidence"""
        try:
            results = self.model(image_path, verbose=False)
            
            if len(results) == 0:
                return None
            
            result = results[0]
            
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
                return None
            
            class_name = CLASS_NAMES.get(class_id, "Unknown")
            is_normal = class_name == "Normal"
            
            # Filter: not Normal AND confidence >= 0.5
            if is_normal or confidence < 0.5:
                return None
            
            return {
                "class_id": class_id,
                "class_name": class_name,
                "confidence": float(confidence),
                "model": "7Classes",
                "is_normal": False
            }
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
                temp_frame_path = video_path.replace(".mp4", f"_7classes_{idx}.jpg").replace(".avi", f"_7classes_{idx}.jpg")
                cv2.imwrite(temp_frame_path, frame)
                frame_paths.append(temp_frame_path)
        
        cap.release()
        return frame_paths, num_frames, consensus_required
    
    def detect_from_video(self, video_path):
        """Detect 7Classes from video - extract key frames with adaptive consensus voting"""
        try:
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                print(f"❌ Could not open video: {video_path}")
                return None
            
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            cap.release()
            
            print(f"🎬 Processing video for 7Classes: {video_path} ({total_frames} total frames)")
            
            # Extract frames with adaptive settings
            frame_paths, num_frames, consensus_required = self._extract_key_frames(video_path, total_frames)
            
            if len(frame_paths) == 0:
                print("⚠️  Could not extract frames from video")
                return None
            
            all_detections = []  # List of (class_name, confidence) tuples
            
            # Process each key frame
            for frame_path in frame_paths:
                try:
                    result = self.detect_from_image(frame_path)
                    if result:
                        # Only count non-Normal predictions
                        if result['class_name'] != "Normal":
                            all_detections.append((result['class_name'], result['confidence']))
                            print(f"  Detected: {result['class_name']} (conf={result['confidence']:.2f})")
                except Exception as e:
                    continue
            
            # Clean up temp frames
            for frame_path in frame_paths:
                Path(frame_path).unlink(missing_ok=True)
            
            print(f"📊 Total 7Classes detections: {len(all_detections)} out of {num_frames} frames")
            
            # Consensus voting: require detection in at least required frames
            if len(all_detections) < consensus_required:
                print(f"⚠️  7Classes consensus not met (detected in {len(all_detections)}/{consensus_required} required frames)")
                return {
                    "class_id": 4,
                    "class_name": "Normal",
                    "confidence": 0.0,
                    "model": "7Classes"
                }
            
            # Get most common non-normal class
            class_names = [class_name for class_name, conf in all_detections]
            top_class = Counter(class_names).most_common(1)[0][0]
            
            # Calculate average confidence for top class
            class_confidences = [conf for class_name, conf in all_detections if class_name == top_class]
            avg_confidence = sum(class_confidences) / len(class_confidences) if class_confidences else 0.0
            
            class_id = [k for k, v in CLASS_NAMES.items() if v == top_class][0]
            
            print(f"🎯 FINAL VERDICT: {top_class.upper()} DETECTED (conf={avg_confidence:.2f}, consensus={len(all_detections)}/{consensus_required})")
            
            return {
                "class_id": class_id,
                "class_name": top_class,
                "confidence": avg_confidence,
                "model": "7Classes"
            }
        except Exception as e:
            print(f"❌ Error in detect_7classes_from_video: {str(e)}")
            import traceback
            traceback.print_exc()
            return None


