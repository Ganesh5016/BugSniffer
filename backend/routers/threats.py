"""Threat detection API endpoints"""

from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from pydantic import BaseModel
from typing import List, Optional
import httpx
import os
from datetime import datetime
import random
from services.ai_engine import analyze_process, batch_analyze, get_risk_level
from services.firebase_service import get_demo_threats, save_scan_report, get_db
from dependencies import get_current_user

router = APIRouter()

ABUSEIPDB_KEY = os.environ.get("ABUSEIPDB_API_KEY", "")
VIRUSTOTAL_KEY = os.environ.get("VIRUSTOTAL_API_KEY", "")


class ProcessData(BaseModel):
    name: str
    pid: Optional[int] = 0
    cpu_usage: float = 0
    memory_usage: float = 0
    battery_drain: float = 0
    network_upload: float = 0
    network_download: float = 0
    background_connections: int = 0
    permission_count: int = 0
    api_calls_per_min: float = 0
    file_ops_per_min: float = 0
    process_injections: int = 0


class DeviceScanRequest(BaseModel):
    device_id: str
    user_id: Optional[str] = "anonymous"
    processes: List[ProcessData]


class ThreatAlertRequest(BaseModel):
    user_id: str
    threat_name: str
    threat_type: str
    severity: str
    device_id: str


@router.post("/analyze-process")
async def analyze_single_process(process: ProcessData):
    """Analyze a single process for threats"""
    result = analyze_process(process.dict())
    result["process_name"] = process.name
    result["pid"] = process.pid
    return result


@router.post("/scan-device")
async def scan_device(request: DeviceScanRequest):
    """Full device scan with AI analysis"""
    results = []
    total_threat_score = 0
    threats_found = []
    
    for proc in request.processes:
        analysis = analyze_process(proc.dict())
        analysis["process_name"] = proc.name
        analysis["pid"] = proc.pid
        results.append(analysis)
        
        total_threat_score += analysis["threat_score"]
        if analysis["threat_score"] > 40:
            threats_found.append({
                "name": proc.name,
                "score": analysis["threat_score"],
                "category": analysis["threat_category"],
                "risk_level": analysis["risk_level"]
            })
    
    device_score = 100 - min(100, total_threat_score / max(len(results), 1))
    
    report = {
        "device_id": request.device_id,
        "scan_timestamp": datetime.utcnow().isoformat(),
        "total_processes": len(results),
        "threats_found": len(threats_found),
        "device_security_score": round(device_score, 1),
        "overall_risk": get_risk_level(100 - device_score),
        "threat_summary": threats_found,
        "detailed_results": results
    }
    
    # Save to Firebase if user provided
    if request.user_id != "anonymous":
        await save_scan_report(request.user_id, {
            "type": "device_scan",
            "device_id": request.device_id,
            "threats_found": len(threats_found),
            "security_score": round(device_score, 1)
        })
    
    return report


@router.get("/recent-threats")
async def get_recent_threats(user: dict = Depends(get_current_user), limit: int = 10):
    """Get recent threat detections"""
    db = get_db()
    if not db:
        return {"threats": [], "total": 0}
        
    uid = user.get("uid")
    # Fetch real threats from Firestore
    scans_ref = db.collection("scan_reports").where("user_id", "==", uid).order_by("created_at", direction="DESCENDING").limit(limit)
    scans_docs = scans_ref.stream()
    
    threats = []
    for doc in scans_docs:
        data = doc.to_dict()
        score = data.get("threat_score", 0)
        if score > 40: # Only return actual threats
            threats.append({
                "id": doc.id,
                "name": data.get("app_name", "Unknown App"),
                "type": data.get("threat_category", "Suspicious"),
                "severity": "critical" if score > 80 else ("high" if score > 60 else "medium"),
                "threat_score": score,
                "confidence": 0.95,
                "timestamp": data.get("created_at", datetime.utcnow()).isoformat()
            })
            
    return {"threats": threats, "total": len(threats)}


@router.get("/threat-stats")
async def get_threat_stats(user: dict = Depends(get_current_user)):
    """Get threat statistics for dashboard"""
    return {
        "total_scans": 0,
        "threats_blocked": 0,
        "malware_detected": 0,
        "phishing_blocked": 0,
        "clean_apps": 0,
        "last_scan": datetime.utcnow().isoformat(),
        "protection_rate": 100.0,
        "daily_threats": [
            {"day": "Mon", "count": 0},
            {"day": "Tue", "count": 0},
            {"day": "Wed", "count": 0},
            {"day": "Thu", "count": 0},
            {"day": "Fri", "count": 0},
            {"day": "Sat", "count": 0},
            {"day": "Sun", "count": 0},
        ]
    }
