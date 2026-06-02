"""APK Scanner API endpoints with VirusTotal integration"""

from fastapi import APIRouter, HTTPException, UploadFile, File, Depends
from dependencies import get_current_user
from services.firebase_service import get_db
from pydantic import BaseModel
from typing import List, Optional
import httpx
import hashlib
import os
import random
import base64
from datetime import datetime
from services.ai_engine import analyze_apk_features, DANGEROUS_PERMISSIONS

router = APIRouter()

VIRUSTOTAL_API_KEY = os.environ.get("VIRUSTOTAL_API_KEY", "")
VIRUSTOTAL_BASE = "https://www.virustotal.com/api/v3"


class AppScanRequest(BaseModel):
    package_name: str
    app_name: str
    version: str = "1.0"
    permissions: List[str] = []
    size_mb: float = 10.0
    uses_internet: bool = True
    background_services: int = 0
    native_code: bool = False
    debuggable: bool = False
    min_sdk: int = 21


async def check_virustotal_hash(file_hash: str) -> dict:
    """Check file hash against VirusTotal"""
    if not VIRUSTOTAL_API_KEY:
        return _simulate_vt_result(file_hash)
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{VIRUSTOTAL_BASE}/files/{file_hash}",
                headers={"x-apikey": VIRUSTOTAL_API_KEY},
                timeout=10.0
            )
            if response.status_code == 200:
                data = response.json()
                stats = data.get("data", {}).get("attributes", {}).get("last_analysis_stats", {})
                return {
                    "found": True,
                    "malicious": stats.get("malicious", 0),
                    "suspicious": stats.get("suspicious", 0),
                    "harmless": stats.get("harmless", 0),
                    "undetected": stats.get("undetected", 0),
                    "total_engines": sum(stats.values()),
                    "hash": file_hash
                }
            elif response.status_code == 404:
                return {"found": False, "hash": file_hash}
        except Exception as e:
            print(f"VirusTotal error: {e}")
    
    return _simulate_vt_result(file_hash)


def _simulate_vt_result(file_hash: str) -> dict:
    """Simulate VirusTotal result for demo"""
    # Make deterministic based on hash
    random.seed(hash(file_hash) % 1000)
    malicious = random.randint(0, 5)
    return {
        "found": True,
        "malicious": malicious,
        "suspicious": random.randint(0, 2),
        "harmless": 60,
        "undetected": random.randint(10, 20),
        "total_engines": 72,
        "hash": file_hash,
        "note": "Demo mode - configure VIRUSTOTAL_API_KEY for real data"
    }


@router.post("/scan-app")
async def scan_application(request: AppScanRequest):
    """Scan an installed app for threats"""
    # AI analysis
    apk_data = {
        "permissions": request.permissions,
        "size_mb": request.size_mb,
        "uses_internet": request.uses_internet,
        "background_services": request.background_services,
        "native_code": request.native_code,
        "debuggable": request.debuggable
    }
    ai_result = analyze_apk_features(apk_data)
    
    # Dangerous permissions check
    dangerous_perms = [p for p in request.permissions if p in DANGEROUS_PERMISSIONS]
    
    # Permission risk score (lower weight so it doesn't falsely flag normal apps)
    perm_score = min(40, len(dangerous_perms) * 4)
    total_score = (ai_result["threat_score"] * 0.5) + (perm_score * 0.5)
    
    # Whitelist popular safe prefixes to avoid false positives
    if request.package_name.startswith(("com.google.", "com.android.", "com.whatsapp", "com.facebook", "com.instagram")):
        total_score = min(total_score, 30.0)
    else:
        total_score = min(100.0, total_score)
    
    return {
        "package_name": request.package_name,
        "app_name": request.app_name,
        "scan_timestamp": datetime.utcnow().isoformat(),
        "threat_score": round(total_score, 1),
        "risk_level": ai_result["risk_level"],
        "threat_category": ai_result["threat_category"],
        "ai_confidence": ai_result["confidence"],
        "is_malicious": total_score > 60,
        "dangerous_permissions": dangerous_perms,
        "total_permissions": len(request.permissions),
        "permission_risk_score": perm_score,
        "ai_analysis": ai_result,
        "recommendations": _get_recommendations(dangerous_perms, total_score)
    }


@router.post("/scan-apk-file")
async def scan_apk_file(file: UploadFile = File(...)):
    """Scan an uploaded APK file"""
    if not file.filename.endswith(".apk"):
        raise HTTPException(status_code=400, detail="File must be an APK")
    
    # Read file and compute hash
    contents = await file.read()
    file_hash = hashlib.sha256(contents).hexdigest()
    md5_hash = hashlib.md5(contents).hexdigest()
    
    # Check VirusTotal
    vt_result = await check_virustotal_hash(file_hash)
    
    # Simulate APK parsing (in production, use androguard)
    size_mb = len(contents) / (1024 * 1024)
    simulated_perms = _simulate_apk_permissions(file_hash)
    
    apk_data = {
        "permissions": simulated_perms,
        "size_mb": size_mb,
        "uses_internet": True,
        "background_services": random.randint(0, 3),
        "native_code": random.choice([True, False]),
        "debuggable": False
    }
    
    ai_result = analyze_apk_features(apk_data)
    
    malicious_ratio = vt_result.get("malicious", 0) / max(vt_result.get("total_engines", 72), 1)
    threat_score = max(ai_result["threat_score"], malicious_ratio * 100)
    
    return {
        "filename": file.filename,
        "file_size_mb": round(size_mb, 2),
        "sha256": file_hash,
        "md5": md5_hash,
        "scan_timestamp": datetime.utcnow().isoformat(),
        "virustotal": vt_result,
        "threat_score": round(threat_score, 1),
        "risk_level": ai_result["risk_level"],
        "threat_category": ai_result["threat_category"],
        "ai_confidence": ai_result["confidence"],
        "is_malicious": vt_result.get("malicious", 0) > 3 or threat_score > 60,
        "permissions_detected": simulated_perms,
        "dangerous_permissions": ai_result.get("dangerous_permissions", []),
        "ai_analysis": ai_result
    }


@router.post("/check-hash")
async def check_file_hash(file_hash: str):
    """Check a file hash against VirusTotal"""
    result = await check_virustotal_hash(file_hash)
    return result


@router.get("/scan-history")
async def get_scan_history(user: dict = Depends(get_current_user)):
    """Get APK scan history"""
    db = get_db()
    if not db:
        return {"history": []}
        
    uid = user.get("uid")
    # Fetch real scan history from Firestore
    scans_ref = db.collection("scan_reports").where("user_id", "==", uid).order_by("created_at", direction="DESCENDING").limit(20)
    scans_docs = scans_ref.stream()
    
    history = []
    for doc in scans_docs:
        data = doc.to_dict()
        score = data.get("threat_score", 0)
        history.append({
            "package_name": data.get("package_name", "Unknown"),
            "app_name": data.get("app_name", "Unknown App"),
            "threat_score": score,
            "risk_level": "critical" if score > 80 else "high" if score > 60 else "low" if score > 20 else "clean",
            "scan_date": data.get("created_at", datetime.utcnow()).isoformat(),
            "threat_category": data.get("threat_category", "Clean" if score < 30 else "Suspicious")
        })
    
    return {"history": history}


def _simulate_apk_permissions(seed: str) -> list:
    """Simulate APK permissions based on hash seed"""
    random.seed(hash(seed) % 10000)
    all_perms = [
        "INTERNET", "ACCESS_NETWORK_STATE", "CAMERA", "RECORD_AUDIO",
        "READ_CONTACTS", "WRITE_CONTACTS", "ACCESS_FINE_LOCATION",
        "READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE",
        "READ_SMS", "SEND_SMS", "RECEIVE_BOOT_COMPLETED",
        "SYSTEM_ALERT_WINDOW", "BIND_ACCESSIBILITY_SERVICE",
        "USE_FINGERPRINT", "VIBRATE", "WAKE_LOCK"
    ]
    count = random.randint(3, 10)
    return random.sample(all_perms, count)


def _get_recommendations(dangerous_perms: list, score: float) -> list:
    recs = []
    if score > 80:
        recs.append("⚠️ CRITICAL: Remove this app immediately")
        recs.append("Run a full device scan")
    elif score > 60:
        recs.append("This app shows suspicious behavior")
        recs.append("Consider removing it")
    
    if "BIND_ACCESSIBILITY_SERVICE" in dangerous_perms:
        recs.append("App requests Accessibility access - potential overlay attack risk")
    if "READ_SMS" in dangerous_perms:
        recs.append("App can read your SMS messages")
    if "RECORD_AUDIO" in dangerous_perms:
        recs.append("App has microphone access")
    if "SYSTEM_ALERT_WINDOW" in dangerous_perms:
        recs.append("App can draw over other apps - phishing risk")
    
    if not recs:
        recs.append("App appears safe. Continue monitoring.")
    
    return recs
