from scripts.crime_model import CrimeModelInference
from scripts.weapons_model import WeaponsModelInference
from scripts.yolo_7classes_model import YOLOSevenClassesInference


class DualModelInference:
    """Orchestrates Crime, Weapons, and 7Classes models with priority system"""
    
    def __init__(self, yolo_model_path, weapons_model_path, pose_model_pt_path, brain_model_path):
        """Initialize all three model detectors"""
        try:
            self.yolo_7classes = YOLOSevenClassesInference(yolo_model_path)
            print(f"✓ 7Classes detector initialized")
        except Exception as e:
            raise Exception(f"Failed to initialize 7Classes: {str(e)}")
        
        self.weapons = WeaponsModelInference(weapons_model_path)
        
        try:
            self.crime = CrimeModelInference(pose_model_pt_path, brain_model_path)
            print(f"✓ Crime detection system initialized")
        except Exception as e:
            print(f"⚠ Warning: Crime model failed to load: {str(e)}")
            self.crime = None
    
    def predict_from_media(self, media_path, media_type):
        """
        Run ALL models always (every model runs regardless).
        Return ALL models that passed the threshold:
        - CRIME: non-Normal AND confidence >= 0.5
        - WEAPONS: confidence >= 0.5
        - 7CLASSES: non-Normal AND confidence >= 0.5
        
        If 2+ models detect incidents: return all
        If 1 model detects incident: return that 1
        If 0 models passed threshold: return no_incident
        """
        try:
            print(f"\n{'='*60}")
            print(f"🔍 Starting prediction for {media_type}: {media_path}")
            print(f"{'='*60}")
            
            valid_incidents = []  # Collect ALL incidents that pass threshold
            
            # === 1. CRIME MODEL - ALWAYS RUNS ===
            if self.crime:
                print("\n1️⃣  RUNNING CRIME MODEL...")
                try:
                    if media_type == "VIDEO":
                        crime_result = self.crime.detect_from_video(media_path)
                    else:
                        crime_result = self.crime.detect_from_image(media_path)
                    
                    if crime_result:
                        print(f"   ✓ Crime result: {crime_result}")
                        # Check: non-Normal AND confidence >= 0.5
                        if not crime_result.get("is_normal", False) and crime_result.get("confidence", 0.0) >= 0.5:
                            valid_incidents.append({
                                "incident_type": crime_result.get("crime_action", "Unknown"),
                                "confidence": crime_result.get("confidence", 0.0),
                                "model": "crime"
                            })
                            print(f"   ✓ Crime ADDED to results (conf >= 0.5)!")
                        else:
                            if crime_result.get("confidence", 0.0) < 0.5:
                                print(f"   ⚠️  Crime below threshold (conf={crime_result.get('confidence', 0.0):.2f})")
                            else:
                                print(f"   ⚠️  Crime classified as Normal")
                    else:
                        print(f"   ⚠️  No crime detected")
                except Exception as e:
                    print(f"   ❌ Crime model error: {str(e)}")
                    import traceback
                    traceback.print_exc()
            else:
                print("1️⃣  ⚠️  Crime model not loaded!")
            
            # === 2. WEAPONS MODEL - ALWAYS RUNS ===
            print("\n2️⃣  RUNNING WEAPONS MODEL...")
            try:
                if media_type == "VIDEO":
                    weapons_result = self.weapons.detect_from_video(media_path)
                else:
                    weapons_result = self.weapons.detect_from_image(media_path)
                
                if weapons_result:
                    print(f"   ✓ Weapon result: {weapons_result}")
                    # Check: confidence >= 0.5
                    if weapons_result.get("confidence", 0.0) >= 0.5:
                        valid_incidents.append({
                            "incident_type": weapons_result.get("class_name", "Unknown"),
                            "confidence": weapons_result.get("confidence", 0.0),
                            "model": "weapons"
                        })
                        print(f"   ✓ Weapon ADDED to results (conf >= 0.5)!")
                    else:
                        print(f"   ⚠️  Weapon below threshold (conf={weapons_result.get('confidence', 0.0):.2f})")
                else:
                    print(f"   ⚠️  No weapon detected")
            except Exception as e:
                print(f"   ❌ Weapons model error: {str(e)}")
            
            # === 3. 7CLASSES MODEL - ALWAYS RUNS ===
            print("\n3️⃣  RUNNING 7CLASSES MODEL...")
            try:
                if media_type == "VIDEO":
                    yolo_result = self.yolo_7classes.detect_from_video(media_path)
                else:
                    yolo_result = self.yolo_7classes.detect_from_image(media_path)
                
                if yolo_result:
                    print(f"   ✓ 7Classes result: {yolo_result}")
                    # Check: non-Normal AND confidence >= 0.5
                    if not yolo_result.get("is_normal", False) and yolo_result.get("confidence", 0.0) >= 0.5:
                        valid_incidents.append({
                            "incident_type": yolo_result.get("class_name", "Unknown"),
                            "confidence": yolo_result.get("confidence", 0.0),
                            "model": "7Classes"
                        })
                        print(f"   ✓ 7Classes ADDED to results (conf >= 0.5)!")
                    else:
                        if yolo_result.get("confidence", 0.0) < 0.5:
                            print(f"   ⚠️  7Classes below threshold (conf={yolo_result.get('confidence', 0.0):.2f})")
                        else:
                            print(f"   ⚠️  7Classes classified as Normal")
                else:
                    print(f"   ⚠️  No 7Classes result")
            except Exception as e:
                print(f"   ❌ 7Classes model error: {str(e)}")
            
            # === RETURN ALL VALID INCIDENTS ===
            print(f"\n{'='*60}")
            print(f"📋 VALID INCIDENTS COLLECTED: {len(valid_incidents)}")
            for inc in valid_incidents:
                print(f"   • {inc['model']}: {inc['incident_type']} (conf={inc['confidence']:.2f})")
            print(f"{'='*60}")
            
            if valid_incidents:
                result = {
                    "incidents": valid_incidents
                }
                print(f"\n✅ FINAL: {result}")
                return result
            
            # No valid incident detected (all below threshold or normal)
            result = {
                "no_incident": True,
                "reason": "All models either below 0.5 confidence or classified as Normal"
            }
            print(f"\n✅ FINAL: {result}")
            return result
        
        except Exception as e:
            print(f"\n❌ ERROR: {str(e)}")
            import traceback
            traceback.print_exc()
            raise Exception(f"Prediction failed: {str(e)}")


