"""Firebase service initialization and helpers"""
import firebase_admin
from firebase_admin import credentials, firestore, auth
import os
import json

_firebase_app = None
_db = None

def init_firebase():
    global _firebase_app, _db
    if not firebase_admin._apps:
        # Use service account from env or file
        cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
        cred_json = os.environ.get("FIREBASE_CREDENTIALS_JSON")
        
        if cred_json:
            cred_dict = json.loads(cred_json)
            cred = credentials.Certificate(cred_dict)
        elif os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
        else:
            # Use default for demo mode
            print("WARNING: Running in demo mode without Firebase credentials")
            return
        
        _firebase_app = firebase_admin.initialize_app(cred)
        _db = firestore.client()

def get_db():
    return _db

def get_auth():
    return auth

async def verify_token(token: str) -> dict:
    """Verify Firebase ID token"""
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise ValueError(f"Invalid token: {e}")

async def save_scan_report(user_id: str, report: dict):
    """Save scan report to Firestore"""
    if _db is None:
        return {"id": "demo_report", "status": "saved"}
    
    doc_ref = _db.collection("scan_reports").document()
    report["user_id"] = user_id
    report["created_at"] = firestore.SERVER_TIMESTAMP
    doc_ref.set(report)
    return {"id": doc_ref.id, "status": "saved"}

async def get_user_threats(user_id: str, limit: int = 10):
    """Get user threat history"""
    if _db is None:
        return get_demo_threats()
    
    threats_ref = _db.collection("threats")\
        .where("user_id", "==", user_id)\
        .order_by("created_at", direction=firestore.Query.DESCENDING)\
        .limit(limit)
    
    docs = threats_ref.stream()
    return [{"id": doc.id, **doc.to_dict()} for doc in docs]

def get_demo_threats():
    """Demo threats for testing without Firebase"""
    return [
        {
            "id": "t1",
            "name": "ShadowRAT.apk",
            "type": "Remote Access Trojan",
            "severity": "critical",
            "threat_score": 94,
            "confidence": 0.97,
            "timestamp": "2024-01-15T10:30:00Z"
        },
        {
            "id": "t2",
            "name": "CryptoMiner.service",
            "type": "Cryptocurrency Miner",
            "severity": "high",
            "threat_score": 78,
            "confidence": 0.89,
            "timestamp": "2024-01-15T09:15:00Z"
        },
        {
            "id": "t3",
            "name": "PhishKit.html",
            "type": "Phishing Page",
            "severity": "high",
            "threat_score": 85,
            "confidence": 0.92,
            "timestamp": "2024-01-15T08:00:00Z"
        }
    ]
