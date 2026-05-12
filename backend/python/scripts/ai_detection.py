"""
AI-Generated Media Detection Gate
-----------------------------------
Runs BEFORE the YOLO models. If the uploaded image/video scores above the
calibrated threshold, the prediction pipeline is aborted and a 422 is returned
to the client.

Detection method: FFT mean high-frequency energy.
  - AI generators (diffusion models, GANs) inject excess energy into the
    high-frequency region of the image spectrum during upsampling.
  - Real photographs do not exhibit this pattern.

Calibrated thresholds (from test data):
  Real images : HF energy 125–161  →  score 38–49  →  PASS
  AI images   : HF energy 168–176  →  score 51–53  →  BLOCK
  Gap at ~165 is the detection boundary.

Public API:
    check_media(file_path: str, media_type: str) -> dict
        Returns: {"is_ai": bool, "score": int, "hf_energy": float}
"""

import warnings
warnings.filterwarnings("ignore")

from pathlib import Path
import numpy as np
import cv2

# ── Calibration constants ─────────────────────────────────────────────────────
FFT_ENERGY_THRESHOLD = 165.0   # HF energy boundary between real and AI
AI_SCORE_THRESHOLD   = 50      # 0–100 score; >= this means AI-generated
VIDEO_SAMPLE_FRAMES  = 6       # Number of frames to sample from a video


# ── Core FFT check ────────────────────────────────────────────────────────────

def _fft_score_from_image(img_gray: np.ndarray) -> tuple[int, float]:
    """
    Compute FFT mean high-frequency energy score for a single grayscale frame.

    Steps:
      1. Resize to 512×512 for consistent measurement.
      2. Compute 2D FFT, shift DC to center.
      3. Convert magnitude to dB.
      4. Zero out the center 60×60 block (low-frequency natural content).
      5. Compute mean of remaining high-frequency energy.
      6. Map to 0–100 score: min(100, int(mean_hf / 165 * 50))

    Returns (score: int, mean_hf: float)
    """
    img = cv2.resize(img_gray, (512, 512))
    f      = np.fft.fft2(img.astype(np.float32))
    fshift = np.fft.fftshift(f)
    h, w   = img.shape
    cy, cx = h // 2, w // 2

    mag = 20 * np.log(np.abs(fshift) + 1e-8)
    mag[cy - 30:cy + 30, cx - 30:cx + 30] = 0   # mask DC center

    mean_hf = float(np.mean(mag))
    score   = min(100, int(mean_hf / FFT_ENERGY_THRESHOLD * 50))
    return score, mean_hf


# ── Public functions ──────────────────────────────────────────────────────────

def check_image(file_path: str) -> dict:
    """
    Run AI detection on a single image file.

    Args:
        file_path: Absolute path to the image (.jpg, .jpeg, .png, etc.)

    Returns:
        {
            "is_ai":     bool,   True if AI-generated
            "score":     int,    0–100 (>= 50 means AI)
            "hf_energy": float,  raw HF energy value
        }
    """
    img = cv2.imread(str(file_path), cv2.IMREAD_GRAYSCALE)
    if img is None:
        # Can't read the file — fail open (don't block a legitimate upload)
        return {"is_ai": False, "score": 0, "hf_energy": 0.0}

    score, hf_energy = _fft_score_from_image(img)
    return {
        "is_ai":     score >= AI_SCORE_THRESHOLD,
        "score":     score,
        "hf_energy": round(hf_energy, 2),
    }


def check_video(file_path: str) -> dict:
    """
    Run AI detection on a video file by sampling evenly-spaced frames.

    Samples VIDEO_SAMPLE_FRAMES frames across the full duration, runs FFT on
    each, then returns the average score. A video is flagged as AI-generated
    if the average frame score >= AI_SCORE_THRESHOLD.

    Args:
        file_path: Absolute path to the video (.mp4, .avi, .mov, etc.)

    Returns:
        {
            "is_ai":          bool,
            "score":          int,   average over sampled frames
            "hf_energy":      float, average HF energy over sampled frames
            "frames_analyzed": int
        }
    """
    cap = cv2.VideoCapture(str(file_path))
    if not cap.isOpened():
        return {"is_ai": False, "score": 0, "hf_energy": 0.0, "frames_analyzed": 0}

    total   = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    indices = np.linspace(0, max(total - 1, 0), VIDEO_SAMPLE_FRAMES, dtype=int)

    scores     = []
    hf_energies = []

    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(idx))
        ret, frame = cap.read()
        if not ret:
            continue
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        s, e = _fft_score_from_image(gray)
        scores.append(s)
        hf_energies.append(e)

    cap.release()

    if not scores:
        return {"is_ai": False, "score": 0, "hf_energy": 0.0, "frames_analyzed": 0}

    avg_score  = int(np.mean(scores))
    avg_energy = round(float(np.mean(hf_energies)), 2)

    return {
        "is_ai":           avg_score >= AI_SCORE_THRESHOLD,
        "score":           avg_score,
        "hf_energy":       avg_energy,
        "frames_analyzed": len(scores),
    }


def check_media(file_path: str, media_type: str) -> dict:
    """
    Dispatcher — call this from main.py.

    Args:
        file_path:  Absolute path to the uploaded file (already saved to disk).
        media_type: "IMAGE" or "VIDEO"

    Returns:
        Same shape as check_image / check_video.
    """
    if media_type == "VIDEO":
        return check_video(file_path)
    return check_image(file_path)
