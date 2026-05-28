"""Dashboard API endpoints"""
from fastapi import APIRouter
import random
from datetime import datetime, timedelta

router = APIRouter()

@router.get("/overview")
async def get_dashboard_overview(user_id: str = "demo"):
    """Get complete dashboard overview"""
    return {
        "security_score": round(random.uniform(72, 95), 1),
        "threat_status": random.choice(["Protected", "Protected", "Warning"]),
        "last_scan": (datetime.utcnow() - timedelta(minutes=random.randint(5, 60))).isoformat(),
        "active_threats": random.randint(0, 3),
        "blocked_today": random.randint(3, 20),
        "device_health": {
            "cpu_usage": round(random.uniform(10, 45), 1),
            "memory_usage": round(random.uniform(30, 70), 1),
            "battery_level": random.randint(40, 100),
            "battery_drain_rate": round(random.uniform(0.5, 3.0), 1),
            "storage_used_pct": round(random.uniform(30, 80), 1)
        },
        "threat_counts": {
            "malware": random.randint(0, 5),
            "spyware": random.randint(0, 3),
            "adware": random.randint(0, 8),
            "phishing": random.randint(0, 10),
            "cryptominer": random.randint(0, 2)
        },
        "network_status": {
            "active_connections": random.randint(5, 25),
            "suspicious_connections": random.randint(0, 3),
            "bandwidth_mb": round(random.uniform(100, 1500), 1),
            "wifi_secure": random.choice([True, True, False])
        },
        "recent_scans": [
            {
                "name": "WhatsApp",
                "score": 8,
                "status": "clean",
                "time": "2m ago"
            },
            {
                "name": "Unknown APK",
                "score": 87,
                "status": "critical",
                "time": "15m ago"
            },
            {
                "name": "Chrome",
                "score": 5,
                "status": "clean",
                "time": "1h ago"
            }
        ]
    }

@router.get("/realtime-metrics")
async def get_realtime_metrics():
    """Get real-time device metrics"""
    return {
        "cpu": round(random.uniform(5, 80), 1),
        "memory": round(random.uniform(30, 85), 1),
        "battery": random.randint(20, 100),
        "temperature": round(random.uniform(30, 50), 1),
        "network_in": random.randint(100, 5000),
        "network_out": random.randint(50, 2000),
        "timestamp": datetime.utcnow().isoformat()
    }
