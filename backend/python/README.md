# YOLO Inference Server Setup

Quick start guide to run the Python FastAPI YOLO inference server.

## Setup

### 1. Navigate to Python Directory

```bash
cd backend/python
```

### 2. Create Virtual Environment

```bash
python -m venv venv
```

### 3. Activate Virtual Environment

**Windows:**

```bash
.\venv\Scripts\activate
```

**macOS/Linux:**

```bash
source venv/bin/activate
```

### 4. Install Requirements

```bash
pip install -r requirements.txt
```

## Run Server

```bash
python main.py
```

Expected output:

```
✓ Model loaded from: ../utils/7Classes/AmanCity_Final_Model.pt
INFO:     Started server process [PID]
INFO:     Uvicorn running on http://0.0.0.0:5001
```

## Test Server

In another terminal:

```bash
curl.exe -X POST http://localhost:5001/health
```

Done! Server is running on **http://localhost:5001** 🚀
