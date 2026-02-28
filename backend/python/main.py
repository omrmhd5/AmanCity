from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import shutil
from pathlib import Path
from inference import YOLOInference

# Initialize FastAPI app
app = FastAPI(title="AmanCity YOLO Inference Server", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize model
MODEL_PATH = os.path.join(os.path.dirname(__file__), "models/7Classes/AmanCity_Final_Model.pt")
try:
    yolo_model = YOLOInference(MODEL_PATH)
    print(f"✓ Model loaded from: {MODEL_PATH}")
except Exception as e:
    print(f"✗ Failed to load model: {str(e)}")
    yolo_model = None

# Temp directory for uploads
TEMP_DIR = Path(__file__).parent / "temp"
TEMP_DIR.mkdir(exist_ok=True)


class PredictionResponse(BaseModel):
    class_id: int
    class_name: str
    confidence: float


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    if yolo_model is None:
        return {"status": "error", "message": "Model not loaded"}
    return {"status": "ok", "message": "YOLO inference server is running"}


@app.post("/predict", response_model=PredictionResponse)
async def predict(file: UploadFile = File(...)):
    """
    Predict incident type from image or video
    
    Accepts:
    - Images: .jpg, .jpeg, .png
    - Videos: .mp4, .avi, .mov
    """
    if yolo_model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    # Validate file type
    allowed_extensions = {".jpg", ".jpeg", ".png", ".mp4", ".avi", ".mov"}
    file_ext = Path(file.filename).suffix.lower()
    
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"File type {file_ext} not supported. Allowed: {', '.join(allowed_extensions)}"
        )

    # Determine media type
    media_type = "VIDEO" if file_ext in {".mp4", ".avi", ".mov"} else "IMAGE"

    # Save temporarily
    temp_path = TEMP_DIR / file.filename
    try:
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Run inference
        result = yolo_model.predict_from_media(str(temp_path), media_type)
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")
    finally:
        # Clean up temp file
        if temp_path.exists():
            temp_path.unlink()


@app.post("/predict-batch")
async def predict_batch(files: list[UploadFile] = File(...)):
    """
    Batch predict multiple files
    """
    if yolo_model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    results = []
    
    for file in files:
        try:
            file_ext = Path(file.filename).suffix.lower()
            allowed_extensions = {".jpg", ".jpeg", ".png", ".mp4", ".avi", ".mov"}
            
            if file_ext not in allowed_extensions:
                results.append({
                    "filename": file.filename,
                    "error": f"Unsupported file type: {file_ext}"
                })
                continue

            media_type = "VIDEO" if file_ext in {".mp4", ".avi", ".mov"} else "IMAGE"
            temp_path = TEMP_DIR / file.filename

            with open(temp_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

            result = yolo_model.predict_from_media(str(temp_path), media_type)
            results.append({
                "filename": file.filename,
                **result
            })

        except Exception as e:
            results.append({
                "filename": file.filename,
                "error": str(e)
            })
        finally:
            if temp_path.exists():
                temp_path.unlink()

    return {"count": len(results), "results": results}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)
