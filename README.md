# 🛡️ BugSniffer — AI Cybersecurity Platform

> Real-time AI-powered malware detection, network monitoring, and privacy protection for Android, iOS, and Web.

---

## 📁 Project Structure

```
bugsniffer/
├── backend/               # FastAPI Python Backend
│   ├── main.py           # Application entry point
│   ├── requirements.txt  # Python dependencies
│   ├── .env.example      # Environment variables template
│   ├── routers/
│   │   ├── auth.py       # Authentication endpoints
│   │   ├── dashboard.py  # Dashboard data
│   │   ├── threats.py    # Threat detection
│   │   ├── scanner.py    # APK scanner (VirusTotal)
│   │   ├── network.py    # Network monitor (AbuseIPDB)
│   │   └── privacy.py    # Privacy protection
│   └── services/
│       ├── ai_engine.py  # Isolation Forest + Random Forest
│       └── firebase_service.py  # Firestore integration
│
├── web/                   # React.js Web Dashboard
│   ├── public/
│   │   └── index.html    # Complete single-file web app
│   ├── src/
│   │   ├── firebase.js   # Firebase configuration
│   │   └── utils/api.js  # API service layer
│   ├── package.json
│   ├── tailwind.config.js
│   └── .env.example
│
└── mobile/               # Flutter Mobile App (Android + iOS)
    ├── lib/
    │   ├── main.dart     # App entry point
    │   ├── screens/      # All app screens
    │   ├── widgets/      # Reusable UI components
    │   └── services/     # API service layer
    └── pubspec.yaml
```

---

## 🚀 Quick Start — All 3 Platforms

### Prerequisites
- Python 3.10+
- Node.js 18+
- Flutter 3.10+ (for mobile)
- Git

---

## 1️⃣ Backend Setup (FastAPI)

```bash
cd bugsniffer/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys (all optional - demo mode works without them)

# Run development server
python main.py

# OR with uvicorn directly
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

✅ Backend runs at: http://localhost:8000  
📚 API Docs: http://localhost:8000/api/docs

---

## 2️⃣ Web Dashboard Setup

**Option A: Simple (Open in Browser)**
```bash
# Just open the file directly - it's a complete standalone app!
open bugsniffer/web/public/index.html
# OR
# Serve with any static server
cd bugsniffer/web/public
python -m http.server 3000
# Open http://localhost:3000
```

**Option B: React development setup**
```bash
cd bugsniffer/web
npm install
cp .env.example .env
# Edit .env with your Firebase config
npm start
```

---

## 3️⃣ Mobile App Setup (Flutter)

```bash
cd bugsniffer/mobile

# Get dependencies
flutter pub get

# Download required fonts (Orbitron, JetBrains Mono)
# Place in assets/fonts/ directory

# Create asset directories
mkdir -p assets/fonts assets/images

# Run on Android
flutter run -d android

# Run on iOS (Mac only)
flutter run -d ios

# Build release APK
flutter build apk --release

# Build iOS IPA
flutter build ios --release
```

---

## 🔑 Free API Keys Setup

All APIs have free tiers. The app works in demo mode without any keys.

### VirusTotal (APK Scanner)
1. Visit https://www.virustotal.com/gui/join-us
2. Register free account
3. Go to your profile → API Key
4. Add to backend `.env`:
   ```
   VIRUSTOTAL_API_KEY=your_key_here
   ```

### AbuseIPDB (IP Reputation)
1. Visit https://www.abuseipdb.com/register
2. Register free account (1000 checks/day)
3. Go to Account → API Keys
4. Add to backend `.env`:
   ```
   ABUSEIPDB_API_KEY=your_key_here
   ```

### Google Safe Browsing (Phishing Detection)
1. Go to https://console.cloud.google.com
2. Create/select a project
3. Enable "Safe Browsing API"
4. Create credentials → API Key
5. Add to backend `.env`:
   ```
   GOOGLE_SAFE_BROWSING_API_KEY=your_key_here
   ```

### Firebase Setup (Auth + Database)
1. Go to https://console.firebase.google.com
2. Create new project (free Spark plan)
3. Enable:
   - Authentication (Email + Google)
   - Firestore Database
   - Cloud Messaging
4. Download `google-services.json` → place in `mobile/android/app/`
5. Download `GoogleService-Info.plist` → place in `mobile/ios/Runner/`
6. Get web config → add to `web/.env`
7. Get service account JSON → add to `backend/.env`

---

## ☁️ Deployment (All Free)

### Backend → Render.com (Free)
```bash
# 1. Push backend code to GitHub
# 2. Go to render.com → New → Web Service
# 3. Connect your GitHub repo
# 4. Settings:
#    - Build Command: pip install -r requirements.txt
#    - Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
#    - Environment: Python 3.11
# 5. Add environment variables in Render dashboard
# 6. Deploy!
```

### Web Dashboard → Vercel (Free)
```bash
# Option 1: Static HTML (simplest)
# 1. Upload web/public/index.html to Vercel
# Go to vercel.com → New Project → Upload
# Done! Gets free HTTPS URL

# Option 2: React app
npm install -g vercel
cd bugsniffer/web
vercel --prod
```

### Web Dashboard → Netlify (Free Alternative)
```bash
# Drag and drop web/public/ folder to netlify.com
# Gets instant HTTPS URL
```

### Mobile → APK Distribution
```bash
# Build signed APK
cd mobile
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
# Share via: Firebase App Distribution (free)
#            or direct download link
```

---

## 🤖 AI Engine Details

The `services/ai_engine.py` implements:

### Isolation Forest
- Detects anomalies in process behavior
- Features: CPU, memory, network, file ops, connections
- Contamination rate: 20% (adjustable)
- Returns: anomaly score, is_anomaly flag

### Random Forest
- Classifies threat type (8 categories)
- Trained on synthetic behavioral data
- Returns: threat category, confidence score
- Categories: Clean, Adware, Spyware, Ransomware, Trojan, Cryptominer, RAT, Keylogger

### Threat Score (0-100)
```
threat_score = isolation_forest_anomaly_score × 0.5
             + random_forest_confidence × 0.5
```

Risk levels:
- 0-20: Clean ✅
- 21-40: Low ℹ️
- 41-60: Medium ⚠️
- 61-80: High 🔴
- 81-100: Critical 🚨

---

## 🛡️ Security Features

| Feature | Technology | API |
|---------|-----------|-----|
| Malware Detection | AI (Isolation Forest + RF) | Built-in |
| APK Scanner | VirusTotal v3 | Free: 4 lookups/min |
| IP Reputation | AbuseIPDB | Free: 1000/day |
| Phishing Detection | Google Safe Browsing | Free: 10,000/day |
| Authentication | Firebase Auth | Free |
| Database | Firebase Firestore | Free |
| Push Notifications | Firebase FCM | Free |

---

## 📱 Features by Platform

| Feature | Web | Android | iOS |
|---------|-----|---------|-----|
| Dashboard | ✅ | ✅ | ✅ |
| Threat Monitor | ✅ | ✅ | ✅ |
| APK Scanner | ✅ | ✅ | ❌* |
| Network Monitor | ✅ | ✅ | ✅ |
| Privacy Center | ✅ | ✅ | ✅ |
| Phishing Detector | ✅ | ✅ | ✅ |
| Push Notifications | ✅ | ✅ | ✅ |
| Dark Mode | ✅ | ✅ | ✅ |
| Cloud Sync | ✅ | ✅ | ✅ |

*iOS doesn't allow APK scanning (Android-specific file format)

---

## 🔧 Configuration

### Backend Environment Variables
```env
PORT=8000
ENV=development
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json
VIRUSTOTAL_API_KEY=optional_but_recommended
ABUSEIPDB_API_KEY=optional_but_recommended
GOOGLE_SAFE_BROWSING_API_KEY=optional_but_recommended
JWT_SECRET=change_in_production
```

### Web Environment Variables
```env
REACT_APP_API_URL=http://localhost:8000
REACT_APP_FIREBASE_API_KEY=your_key
REACT_APP_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=your-project-id
```

### Mobile Configuration
Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-render-app.onrender.com';
```

---

## 🌟 Demo Mode

**Everything works without any API keys!**

- AI engine uses scikit-learn models trained locally
- Simulated threat data is generated deterministically
- All UI features fully functional
- Just run the backend and open the web app

Default demo credentials: any email/password combination

---

## 📊 Firebase Firestore Structure

```
/users/{userId}
  - email, displayName, createdAt, plan

/scan_reports/{reportId}
  - userId, deviceId, type, threatsFound, securityScore, createdAt

/threats/{threatId}
  - userId, name, type, severity, threatScore, confidence, timestamp

/devices/{deviceId}
  - userId, platform, lastSeen, securityScore
```

---

## 🐛 Troubleshooting

**Backend won't start:**
```bash
pip install --upgrade pip
pip install -r requirements.txt --force-reinstall
```

**Flutter build fails:**
```bash
flutter clean
flutter pub get
flutter run
```

**Web app can't reach backend:**
- Make sure backend is running on port 8000
- For production: update API_URL in web/public/index.html (line ~1420)
- Check CORS settings in backend/main.py

**Firebase errors:**
- App works in demo mode without Firebase
- For production: complete Firebase setup in Prerequisites

---

## 📄 License

MIT License — Free for personal and commercial use.

---

Built with ❤️ using FastAPI, Flutter, React, Firebase, and scikit-learn.
