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

## 📸 Screenshots & System Overview

<p align="center">
  <img width="100%" alt="AmanCity Poster" src="https://github.com/user-attachments/assets/7ef39499-b83a-4168-804f-76a705990154" />
</p>

### 📱 User Interface

<table>
  <tr>
    <td align="center"><b>Home Screen (Dark)</b></td>
    <td align="center"><b>Home Screen (Arabic)</b></td>
    <td align="center"><b>Incoming Notifications & Alerts</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="Home Screen After Login (Dark)" src="https://github.com/user-attachments/assets/f750d181-86b7-4fea-b8aa-51c4106098da" /></td>
    <td><img width="100%" alt="Home Screen Arabic (Dark)" src="https://github.com/user-attachments/assets/2daac5c2-a092-4d95-9df0-7e2f4b59608a" /></td>
    <td><img width="100%" alt="Alerts Screen Showing Incoming Notifications and Alerts" src="https://github.com/user-attachments/assets/6322d730-1ed9-44a8-88ba-7d9d15e26db8" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>Interactive Safety Map & Hotspots</b></td>
    <td align="center"><b>Safest Route Home & Safety Scores</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="Map Screen Showing Incident Markers and Hotspot Zone and POI Markers" src="https://github.com/user-attachments/assets/b6f459f1-b31b-4af5-a77d-8b001a64bc22" /></td>
    <td><img width="100%" alt="Map Screen Showing Safest Route Home With Safety Scores" src="https://github.com/user-attachments/assets/72d4fdd9-c042-4b77-8aa0-608aa500b5b4" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>Map Screen POI Details</b></td>
    <td align="center"><b>Map Screen Hotspot Details</b></td>
    <td align="center"><b>Bulk Incident Details & Evidence</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="Map Screen POI Details" src="https://github.com/user-attachments/assets/738798c5-0b64-47ec-b7d5-9e76f2bbda0f" /></td>
    <td><img width="100%" alt="Map Screen Showing Hotspot Details" src="https://github.com/user-attachments/assets/12f1c756-6b6c-468d-b44e-812602384a8d" /></td>
    <td><img width="100%" alt="Map Screen Showing Bulk Incident Details And Its Evidence" src="https://github.com/user-attachments/assets/d9223b6f-ff86-4ebc-821b-792b054be07a" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>Newly Submitted Incident</b></td>
    <td align="center"><b>Incidents Details #1 (AI Confidence)</b></td>
    <td align="center"><b>Incidents Details #2 (Location)</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="Map Screen Showing Newely Submitted Incident" src="https://github.com/user-attachments/assets/118a0dd6-7a94-42e2-a857-56a136bd0926" /></td>
    <td><img width="100%" alt="Map Screen Showing Incidents Details #1 (Reported By, AI Confidence, Evidence)" src="https://github.com/user-attachments/assets/9179d683-07e9-43b1-974d-93f3b4d6b647" /></td>
    <td><img width="100%" alt="Map Screen Showing Incidents Details #2 (Location)" src="https://github.com/user-attachments/assets/7eec5167-fdff-460c-a1e1-62d5856d22e1" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>Incident Reporting & AI Prediction</b></td>
    <td align="center"><b>Synthetic Media Gate Rejection Alert</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="Report Screen Showing Result Fire Prediction" src="https://github.com/user-attachments/assets/cadf7959-ef95-47af-9d1e-008febc2f679" /></td>
    <td><img width="100%" alt="Report Screen Showing AI-Generated Content" src="https://github.com/user-attachments/assets/989222e0-67d2-4a80-bdac-3c01a6047ff8" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>AI Assistant (Nearby Incidents)</b></td>
    <td align="center"><b>AI Assistant (Safest Route)</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="AI Screen Saying Nearby Incidents" src="https://github.com/user-attachments/assets/833e8e58-a357-4238-9a6e-9ef53ddd248b" /></td>
    <td><img width="100%" alt="AI Screen Showing Safest Home Route" src="https://github.com/user-attachments/assets/99504fcc-7e4f-4265-9c74-3b611e73694a" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>SOS Trigger Alert</b></td>
    <td align="center"><b>SOS Incoming Alert</b></td>
    <td align="center"><b>SOS Live Tracking</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="SOS Trigger Alert Screen" src="https://github.com/user-attachments/assets/4ebb4bad-6cca-4254-bf09-71ed85fb9563" /></td>
    <td><img width="100%" alt="SOS Incoming Alert Screen" src="https://github.com/user-attachments/assets/969f7913-6651-4f28-b746-31f35775a348" /></td>
    <td><img width="100%" alt="SOS Live Tracking Screen" src="https://github.com/user-attachments/assets/3bbde0f4-11ba-4110-9266-968c7dbc51ca" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>OSINT News Feed (Incidents)</b></td>
    <td align="center"><b>OSINT News Feed (Search)</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="News Screen Showing Incidents (Dark)" src="https://github.com/user-attachments/assets/f52a18ed-b08d-4834-a5a8-e8e0fa315a64" /></td>
    <td><img width="100%" alt="News Screen Showing Search Results" src="https://github.com/user-attachments/assets/98d41f7c-1422-4da3-814c-e33318f23cbe" /></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><b>Authority Dashboard (Incident Details)</b></td>
    <td align="center"><b>Authority Dashboard (Statistics)</b></td>
    <td align="center"><b>Authority Dashboard (SOS Triggers)</b></td>
  </tr>
  <tr>
    <td><img width="100%" alt="Authority Dashboard Screen Showing All Incident Details" src="https://github.com/user-attachments/assets/94a552b7-4fd9-47a1-8314-a7f8578f58e4" /></td>
    <td><img width="100%" alt="Authority Dashboard Screen Showing Summary Of Statistics" src="https://github.com/user-attachments/assets/ba9f5c21-37cc-41eb-b892-223f166f7ff4" /></td>
    <td><img width="100%" alt="Authority Dashboard Screen Showing SOS triggers" src="https://github.com/user-attachments/assets/c1425f15-beb1-4645-a2da-9466f77ee4ba" /></td>
  </tr>
</table>

---

## Video Demo 🚀

[**View Video Demo**](https://youtu.be/0-Qayg2_9uc)

---

## Author

👤 **Omar Mahmoud**  
📧 [omrmhd54@gmail.com](mailto:omrmhd54@gmail.com)  
🔗 [GitHub](https://github.com/omrmhd5)
