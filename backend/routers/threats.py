"""Threat detection API endpoints"""

from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
import httpx
import os
from datetime import datetime
import random
from services.ai_engine import analyze_process, batch_analyze, get_risk_level
from services.firebase_service import get_demo_threats, save_scan_report

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
async def get_recent_threats(user_id: str = "demo", limit: int = 10):
    """Get recent threat detections"""
    # Return demo data + generated threats
    base_threats = get_demo_threats()
    
    # Add some dynamic entries
    dynamic_threats = [
        {
            "id": f"dynamic_{i}",
            "name": random.choice([
                "SuspiciousService.apk", "DataHarvest.exe", 
                "FakeBank.apk", "ClickFraud.js",
                "AdwareKit.dll", "SMSInterceptor.apk"
            ]),
            "type": random.choice([
                "Adware", "Spyware", "Phishing", "Trojan", "Cryptominer"
            ]),
            "severity": random.choice(["low", "medium", "high", "critical"]),
            "threat_score": random.randint(30, 95),
            "confidence": round(random.uniform(0.75, 0.99), 2),
            "timestamp": datetime.utcnow().isoformat()
        }
        for i in range(3)
    ]
    
    all_threats = base_threats + dynamic_threats
    return {"threats": all_threats[:limit], "total": len(all_threats)}


@router.get("/threat-stats")
async def get_threat_stats():
    """Get threat statistics for dashboard"""
    return {
        "total_scans": random.randint(150, 300),
        "threats_blocked": random.randint(20, 50),
        "malware_detected": random.randint(5, 15),
        "phishing_blocked": random.randint(10, 30),
        "clean_apps": random.randint(100, 200),
        "last_scan": datetime.utcnow().isoformat(),
        "protection_rate": round(random.uniform(97.5, 99.9), 1),
        "daily_threats": [
            {"day": "Mon", "count": random.randint(2, 15)},
            {"day": "Tue", "count": random.randint(2, 15)},
            {"day": "Wed", "count": random.randint(2, 15)},
            {"day": "Thu", "count": random.randint(2, 15)},
            {"day": "Fri", "count": random.randint(2, 15)},
            {"day": "Sat", "count": random.randint(2, 15)},
            {"day": "Sun", "count": random.randint(2, 15)},
        ]
    }
