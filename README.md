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
 <img width="378" height="834" alt="Home Screen After Login (Dark)" src="https://github.com/user-attachments/assets/f750d181-86b7-4fea-b8aa-51c4106098da" />


 <img width="378" height="837" alt="Home Screen Arabic (Dark)" src="https://github.com/user-attachments/assets/2daac5c2-a092-4d95-9df0-7e2f4b59608a" />

- Interactive Safety Map with Hotspot Overlays
<img width="373" height="822" alt="Map Screen Showing Incident Markers and Hotspot Zone and POI Markers" src="https://github.com/user-attachments/assets/b6f459f1-b31b-4af5-a77d-8b001a64bc22" />
<img width="376" height="833" alt="Map Screen Showing Safest Route Home With Safety Scores" src="https://github.com/user-attachments/assets/72d4fdd9-c042-4b77-8aa0-608aa500b5b4" />




- 
- Incident Reporting with AI Prediction Result

- <img width="376" height="836" alt="Report Screen Showing Result Fire Prediction" src="https://github.com/user-attachments/assets/cadf7959-ef95-47af-9d1e-008febc2f679" />



- Synthetic Media Gate Rejection Alert
<img width="378" height="837" alt="Report Screen Showing AI-Generated Content" src="https://github.com/user-attachments/assets/989222e0-67d2-4a80-bdac-3c01a6047ff8" />
- 
- AI Safety Assistant (Gemini) Chat
- <img width="376" height="830" alt="AI Screen Saying Nearby Incidents" src="https://github.com/user-attachments/assets/833e8e58-a357-4238-9a6e-9ef53ddd248b" />
<img width="376" height="833" alt="AI Screen Showing Safest Home Route" src="https://github.com/user-attachments/assets/99504fcc-7e4f-4265-9c74-3b611e73694a" />


- SOS Activation & Live Tracking

-
- <img width="376" height="831" alt="SOS Trigger Alert Screen" src="https://github.com/user-attachments/assets/4ebb4bad-6cca-4254-bf09-71ed85fb9563" />
<img width="376" height="832" alt="SOS Incoming Alert Screen" src="https://github.com/user-attachments/assets/969f7913-6651-4f28-b746-31f35775a348" />
<img width="378" height="834" alt="SOS Live Tracking Screen" src="https://github.com/user-attachments/assets/3bbde0f4-11ba-4110-9266-968c7dbc51ca" />



- OSINT News Feed (Grok-4 Integration)
- <img width="378" height="835" alt="News Screen Showing Incidents (Dark)" src="https://github.com/user-attachments/assets/f52a18ed-b08d-4834-a5a8-e8e0fa315a64" />
<img width="376" height="834" alt="News Screen Showing Search Results" src="https://github.com/user-attachments/assets/98d41f7c-1422-4da3-814c-e33318f23cbe" />


- 
- Authority Statistics Dashboard
-
  <img width="378" height="837" alt="Authority Dashboard Screen Showing All Incident Details" src="https://github.com/user-attachments/assets/94a552b7-4fd9-47a1-8314-a7f8578f58e4" />
  <img width="378" height="836" alt="Authority Dashboard Screen Showing Summary Of Statistics" src="https://github.com/user-attachments/assets/ba9f5c21-37cc-41eb-b892-223f166f7ff4" />


<img width="3685" height="2551" alt="Omar232848_AmanCity_Poster" src="https://github.com/user-attachments/assets/7ef39499-b83a-4168-804f-76a705990154" />


---

## Video Demo 🚀

[**View Video Demo**](https://youtu.be/0-Qayg2_9uc)

---

## Author

👤 **Omar Mahmoud**  
📧 [omrmhd54@gmail.com](mailto:omrmhd54@gmail.com)  
🔗 [GitHub](https://github.com/omrmhd5)
