# 🛡️ AmanCity – AI-Powered Urban & Women Safety Platform

A fully localized AI-powered urban and women's safety platform built for **Egypt (Greater Cairo)**, designed to address the fragmented nature of incident reporting. The platform integrates Computer Vision, Natural Language Processing, and Predictive Machine Learning to detect incidents from crowdsourced media and OSINT data, mapping them in real-time. It significantly improves situational awareness by providing live alerts, predictive risk mapping, and a robust session-based SOS system tailored for personal and women's safety.

AmanCity introduces the first active eco-system of safety in Egypt, successfully combining 8 distinct safety capabilities into a single, Arabic-first platform. The system validates crowdsourced data integrity through FFT analysis and transforms raw social and visual data into actionable safety insights.

---

## 🔧 Features

### 📸 Crowdsourced Incident Reporting & AI Gate

- Users can report incidents by uploading geo-tagged images, videos, or text.
- **FFT-based Synthetic Media Gate**: An inline filter that analyzes high-frequency energy to block AI-generated fake images and deepfakes before inference, ensuring data integrity.

### 👁️ Tri-Model Computer Vision Inference

- Three AI models run simultaneously on user uploads using YOLO26 and Random Forest architectures:
  - **Environmental Classifier**: Detects 7 classes (Fire, Flood, Accident, Road Damage, Damaged Building, Public Issue, Normal).
  - **Weapons Detector**: Detects 2 classes (Firearm, Cold Weapon).
  - **Crime Action Recognizer**: Extracts 17-point skeleton poses to detect 11 actions (Assault, Fighting, Robbery, Arson, Shooting, Shoplifting, Stealing, Burglary, Vandalism, Arrest, Explosion).

### 🌐 Social Media Intelligence (OSINT Engine)

- Real-time bilingual (Arabic & English) scanning of X (Twitter) using the **xAI Grok-4 API**.
- Automated extraction of incident title, type, location, and severity from community text updates.
- URL matching and spatial-temporal filtering (500m / 1-hour threshold) to prevent duplicate reports.

### 🗺️ Predictive Hotspot & Interactive Map

- **DBSCAN Spatial Clustering**: Forecasts high-density risk zones and generates danger radii based on a 24-hour rolling window of incidents.
- **Interactive Safety Map**: Renders live incident markers, predicted hotspot overlays, and real-time Emergency POIs (hospitals, police, fire stations) via Google Places API.
- Dynamic filtering by incident type, time, and severity.

### 🚨 SOS & Women's Safety System

- **Session-Based Tracking**: Persistent SOS sessions in MongoDB with a 24-hour TTL auto-delete.
- Immediate on-device visual and audible signals (Alarm & Flashlight) to deter immediate threats.
- Instant push notifications (FCM) and a continuous live location sharing loop to accepted trusted emergency contacts.

### 🛣️ Safe Route & Gemini Assistant

- **Safe Route Planner**: Calculates optimized navigation paths avoiding active threat zones using Haversine distance logic and the Google Directions API.
- **Conversational Safety Assistant**: Powered by **Google Gemini 3.5 Flash**, providing natural-language, context-aware safety advisories injected with live local incident data (e.g., "Is Nasr City safe right now?").

### 📊 Authority Dashboard

- Centralized administrative command portal with role-restricted secure access.
- Real-time analytics grid displaying total system records, active hotspots, and historical trends.
- Live operational ledgers and source distributions (Human vs. OSINT).

---

## 🧠 Dataset & AI Training

The AI models were trained on highly curated, consolidated datasets:

- **Environmental**: Aggregated from 10 public sources (Kaggle, AlleyFloodNet, AIDER) and annotated via Roboflow.
- **Weapons**: Unified from 8 sources including DatasetNinja and Kaggle CCTV datasets.
- **Crime Action**: Built from UCF-Crime, Real-Life Violence Situations, and Movies Fight Detection datasets using 34-dimensional skeleton pose vectors.

---

## 💡 Impact

- **Unified Ecosystem:** Combines 8 distinct safety capabilities into a single platform, eliminating the need for fragmented reactive hotlines.
- **Data Integrity:** Protects the platform from misinformation by actively blocking AI-generated synthetic media before inference.
- **Proactive Safety:** Shifts urban safety from reactive to proactive through DBSCAN predictive mapping and Safe Route generation.
- **Empowerment:** Provides robust, session-backed emergency support tailored for women and vulnerable groups in public spaces.

---

## 🚀 Future Roadmap

- **Vision-Language Models (VLM)**: Transitioning from fixed-class classification to open-class incident understanding.
- **Temporal Crime Recognition**: Implementing LSTM/Transformer models over pose time sequences for advanced behavioral tracking.
- **Advanced Forecasting**: Replacing DBSCAN with spatio-temporal LSTM or graph-based forecasting.
- **Hardware SOS**: Integrating shake/volume-button SOS activation and smartwatch compatibility for immediate distress signaling.

---

## 📦 Tech Stack

| Layer         | Tech                                          |
| ------------- | --------------------------------------------- |
| Frontend      | Flutter (Dart), Google Maps SDK               |
| Backend       | Node.js, Express.js                           |
| Database      | MongoDB (Mongoose, GeoJSON)                   |
| AI Server     | Python, FastAPI, YOLO26, OpenCV, scikit-learn |
| Auth & Push   | Firebase Authentication, FCM                  |
| External APIs | xAI Grok-4, Google Gemini 3.5 Flash           |

---

## 🌐 Deployment Notes

- Full Arabic and English localization with RTL/LTR support.
- Dark / Light theme UI matching system preferences.
- Designed to scale across all Egyptian governorates.
- Distributed architecture (Client → API Gateway → Backend → AI Server → DB).

---

## 📸 Screenshots

- Home Screen (Arabic Localization & Dark Theme)
- Interactive Safety Map with Hotspot Overlays
- Incident Reporting with AI Prediction Result
- Synthetic Media Gate Rejection Alert
- AI Safety Assistant (Gemini) Chat
- SOS Activation & Live Tracking
- OSINT News Feed (Grok-4 Integration)
- Authority Statistics Dashboard

_(Note: Add screenshot image links here)_

---

## Video Demo 🚀

[**View Video Demo**](https://youtu.be/0-Qayg2_9uc)

---

## Author

👤 **Omar Mahmoud**
📧 [omrmhd54@gmail.com](mailto:omrmhd54@gmail.com)
🔗 [GitHub](https://github.com/omrmhd5)
