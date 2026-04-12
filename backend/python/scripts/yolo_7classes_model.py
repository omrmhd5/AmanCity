import cv2
import numpy as np
from ultralytics import YOLO
from collections import Counter

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
        """Detect 7Classes from image"""
        try:
            results = self.model(image_path, verbose=False)
            
            if len(results) == 0:
                raise Exception("No results from YOLO inference")
            
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
    
    def detect_from_video(self, video_path):
        """Detect 7Classes from video - processes every 3rd frame"""
        try:
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                print(f"❌ Could not open video: {video_path}")
                return None
            
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            frame_skip = 3  # Process every 3rd frame
            frame_count = 0
            frames_processed = 0  # Track actual frames processed
            all_predictions = []  # Collect ALL predictions: (frame_num, class_name) tuples
            frame_predictions = {}  # Track predictions per frame
            
            print(f"🎬 Processing video for 7Classes: {video_path} ({total_frames} total frames)")
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
                frame_count += 1
                
                # Only process every 3rd frame
                if frame_count % frame_skip == 1:
                    frames_processed += 1  # Increment frames processed
                    frame_predictions[frame_count] = []  # Track predictions for this frame
                    try:
                        results = self.model(frame, verbose=False)
                        
                        if len(results) > 0:
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
                                continue
                            
                            class_name = CLASS_NAMES.get(class_id, "Unknown")
                            # Only store if confidence >= 0.5 threshold
                            if confidence >= 0.5:
                                all_predictions.append((frame_count, class_name, confidence))
                                frame_predictions[frame_count].append(class_name)
                                print(f"  Frame {frame_count}: {class_name} (conf={confidence:.2f})")
                    except Exception as e:
                        continue
            
            cap.release()
            
            print(f"📊 Total 7Classes predictions collected: {len(all_predictions)}")
            
            if not all_predictions:
                print("⚠️  No predictions detected in video")
                return None
            
            # Filter out "Normal" predictions
            non_normal = [(frame, label, conf) for frame, label, conf in all_predictions if label != "Normal"]
            
            print(f"🔍 Non-Normal found: {len(non_normal)} out of {len(all_predictions)}")
            
            if not non_normal:
                # All predictions were Normal
                print("✓ All predictions were Normal")
                return {
                    "class_id": 4,
                    "class_name": "Normal",
                    "confidence": 0.0,
                    "model": "7Classes",
                    "prediction_count": frames_processed,
                    "is_normal": True
                }
            
            # Get the MOST COMMON non-normal class
            class_names = [label for frame, label, conf in non_normal]
            top_class, _ = Counter(class_names).most_common(1)[0]
            
            # Calculate average confidence from all non-normal detections for top class
            class_confidences = []
            for frame_num, class_name, conf in non_normal:
                if class_name == top_class:
                    class_confidences.append(conf)
            
            confidence = sum(class_confidences) / len(class_confidences) if class_confidences else 0.0
            
            print(f"🎯 FINAL VERDICT: {top_class.upper()} DETECTED ({len(class_confidences)} detections, conf={confidence:.2f})")
            
            class_id = [k for k, v in CLASS_NAMES.items() if v == top_class][0]
            
            return {
                "class_id": class_id,
                "class_name": top_class,
                "confidence": confidence,
                "model": "7Classes",
                "prediction_count": len(all_predictions),
                "is_normal": False
            }
        except Exception as e:
            print(f"❌ Error in detect_7classes_from_video: {str(e)}")
            import traceback
            traceback.print_exc()
            return None


