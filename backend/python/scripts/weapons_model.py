import cv2
import numpy as np
from ultralytics import YOLO
from pathlib import Path

WEAPON_CONFIDENCE_THRESHOLD = 0.5
CLASS_NAMES = {
    7: "Firearm",
    8: "Cold Weapon",
}


class WeaponsModelInference:
    """Weapons detection using YOLO ONNX model"""
    
    def __init__(self, weapons_model_path):
        """Initialize weapons detector"""
        try:
            self.model = YOLO(weapons_model_path)
            print(f"✓ Weapons ONNX model loaded from: {weapons_model_path}")
        except Exception as e:
            print(f"⚠ Warning: Weapons model failed to load: {str(e)}")
            self.model = None
    
    def detect_from_image(self, image_path):
        """Detect weapons in image - returns detection or None"""
        if self.model is None:
            return None
        
        try:
            results = self.model.predict(image_path, conf=0.0, verbose=False)
            
            if len(results) == 0:
                return None
            
            result = results[0]
            
            if len(result.boxes) > 0:
                confidences = result.boxes.conf.cpu().numpy()
                class_ids = result.boxes.cls.cpu().numpy().astype(int)
                max_idx = np.argmax(confidences)
                max_confidence = float(confidences[max_idx])
                onnx_class_id = int(class_ids[max_idx])
                
                if max_confidence >= WEAPON_CONFIDENCE_THRESHOLD:
                    # Map ONNX output (0 or 1) to class names (7 or 8)
                    class_id = 7 + onnx_class_id
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
                temp_frame_path = video_path.replace(".mp4", f"_weapon_{idx}.jpg").replace(".avi", f"_weapon_{idx}.jpg")
                cv2.imwrite(temp_frame_path, frame)
                frame_paths.append(temp_frame_path)
        
        cap.release()
        return frame_paths, num_frames, consensus_required
    
    def detect_from_video(self, video_path):
        """Detect weapons from video - extract key frames with adaptive consensus voting"""
        if self.model is None:
            print("❌ Weapons model not loaded!")
            return None
        
        try:
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                print(f"❌ Could not open video: {video_path}")
                return None
            
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            cap.release()
            
            print(f"🎬 Processing video for weapons: {video_path} ({total_frames} total frames)")
            
            # Extract frames with adaptive settings
            frame_paths, num_frames, consensus_required = self._extract_key_frames(video_path, total_frames)
            
            if len(frame_paths) == 0:
                print("⚠️  Could not extract frames from video")
                return None
            
            best_weapon_result = None
            highest_confidence = 0
            all_detections = []
            
            # Process each key frame
            for frame_path in frame_paths:
                try:
                    result = self.detect_from_image(frame_path)
                    if result:
                        all_detections.append(result)
                        print(f"  Detected: {result['class_name']} (conf={result['confidence']:.2f})")
                        
                        # Track best detection
                        if result['confidence'] > highest_confidence:
                            highest_confidence = result['confidence']
                            best_weapon_result = result
                except Exception as e:
                    continue
            
            # Clean up temp frames
            for frame_path in frame_paths:
                Path(frame_path).unlink(missing_ok=True)
            
            print(f"📊 Total weapon detections: {len(all_detections)} out of {num_frames} frames")
            
            # Consensus voting: require detection in at least required frames
            if len(all_detections) < consensus_required:
                print(f"⚠️  Weapon consensus not met (detected in {len(all_detections)}/{consensus_required} required frames)")
                return None
            
            if not best_weapon_result:
                print("⚠️  No weapons detected in video")
                return None
            
            print(f"🎯 FINAL VERDICT: {best_weapon_result['class_name'].upper()} DETECTED (conf={best_weapon_result['confidence']:.2f}, consensus={len(all_detections)}/{consensus_required})")
            
            return best_weapon_result
        
        except Exception as e:
            print(f"❌ Error in detect_weapons_from_video: {str(e)}")
            import traceback
            traceback.print_exc()
            return None

