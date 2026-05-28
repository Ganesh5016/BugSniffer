"""Dashboard API endpoints"""
from fastapi import APIRouter, Depends, Body
from datetime import datetime
from dependencies import get_current_user
from services.firebase_service import get_db

router = APIRouter()

@router.get("/overview")
async def get_dashboard_overview(user: dict = Depends(get_current_user)):
    """Get complete dashboard overview from real Firestore data"""
    db = get_db()
    uid = user.get("uid")
    
    # Default safe data if user has no data yet
    result = {
        "security_score": 100.0,
        "threat_status": "Protected",
        "last_scan": datetime.utcnow().isoformat(),
        "active_threats": 0,
        "blocked_today": 0,
        "device_health": {
            "cpu_usage": 0,
            "memory_usage": 0,
            "battery_level": 100,
            "temperature": 0
        },
        "network_status": {
            "active_connections": 0,
            "suspicious_connections": 0,
            "wifi_secure": True
        },
        "recent_scans": []
    }
    
    if db is None:
        return result
        
    # Fetch user's latest metrics
    metrics_ref = db.collection("users").document(uid).collection("metrics").order_by("timestamp", direction="DESCENDING").limit(1)
    metrics_docs = metrics_ref.stream()
    
    for doc in metrics_docs:
        data = doc.to_dict()
        result["device_health"] = {
            "cpu_usage": data.get("cpu", 0),
            "memory_usage": data.get("memory", 0),
            "battery_level": data.get("battery", 100),
            "temperature": data.get("temperature", 0)
        }
        result["network_status"]["active_connections"] = data.get("active_connections", 0)
        result["network_status"]["wifi_secure"] = data.get("wifi_secure", True)
        break
        
    # Fetch user's recent scans
    scans_ref = db.collection("scan_reports").where("user_id", "==", uid).order_by("created_at", direction="DESCENDING").limit(3)
    scans_docs = scans_ref.stream()
    scans = []
    active_threats = 0
    
    for doc in scans_docs:
        data = doc.to_dict()
        score = data.get("threat_score", 0)
        status = "clean"
        if score > 60:
            status = "high"
        if score > 80:
            status = "critical"
            active_threats += 1
            
        scans.append({
            "name": data.get("app_name", "Unknown App"),
            "score": score,
            "status": status,
            "time": data.get("created_at", datetime.utcnow()).isoformat()
        })
        
    result["recent_scans"] = scans
    result["active_threats"] = active_threats
    if active_threats > 0:
        result["threat_status"] = "At Risk"
        result["security_score"] = max(0, 100 - (active_threats * 15))
        
    return result

@router.post("/telemetry")
async def post_telemetry(metrics: dict = Body(...), user: dict = Depends(get_current_user)):
    """Save real-time device metrics to Firestore"""
    db = get_db()
    if db:
        metrics["timestamp"] = datetime.utcnow()
        db.collection("users").document(user["uid"]).collection("metrics").add(metrics)
    return {"status": "success"}

@router.get("/realtime-metrics")
async def get_realtime_metrics(user: dict = Depends(get_current_user)):
    """Get the latest real-time device metrics for the user"""
    db = get_db()
    if not db:
        return {"cpu": 0, "memory": 0, "battery": 100, "temperature": 0, "network_in": 0, "network_out": 0}
        
    metrics_ref = db.collection("users").document(user["uid"]).collection("metrics").order_by("timestamp", direction="DESCENDING").limit(1)
    docs = metrics_ref.stream()
    for doc in docs:
        data = doc.to_dict()
        data["timestamp"] = data["timestamp"].isoformat() if hasattr(data["timestamp"], "isoformat") else data["timestamp"]
        return data
        
    return {"cpu": 0, "memory": 0, "battery": 100, "temperature": 0, "network_in": 0, "network_out": 0}
