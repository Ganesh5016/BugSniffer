"""Privacy Protection API endpoints"""
from fastapi import APIRouter
import random
from datetime import datetime, timedelta

router = APIRouter()

@router.get("/status")
async def get_privacy_status(device_id: str = "demo"):
    """Get privacy protection status"""
    return {
        "camera_in_use": False,
        "microphone_in_use": False,
        "clipboard_monitoring": True,
        "overlay_detected": False,
        "location_apps": random.randint(2, 8),
        "background_data_apps": random.randint(5, 15),
        "permission_alerts": random.randint(0, 5),
        "privacy_score": random.randint(70, 95),
        "last_checked": datetime.utcnow().isoformat()
    }

@router.get("/app-permissions")
async def get_app_permissions():
    """Get apps with sensitive permissions"""
    return {
        "apps": [
            {
                "name": "WhatsApp",
                "package": "com.whatsapp",
                "permissions": ["CAMERA", "RECORD_AUDIO", "READ_CONTACTS", "ACCESS_FINE_LOCATION"],
                "risk": "medium",
                "risk_score": 35
            },
            {
                "name": "Unknown VPN",
                "package": "com.fakevpn.pro",
                "permissions": ["RECORD_AUDIO", "ACCESS_FINE_LOCATION", "READ_SMS", "BIND_ACCESSIBILITY_SERVICE"],
                "risk": "critical",
                "risk_score": 88
            },
            {
                "name": "Instagram",
                "package": "com.instagram.android",
                "permissions": ["CAMERA", "RECORD_AUDIO", "ACCESS_FINE_LOCATION"],
                "risk": "medium",
                "risk_score": 40
            },
            {
                "name": "Chrome",
                "package": "com.android.chrome",
                "permissions": ["CAMERA", "ACCESS_FINE_LOCATION"],
                "risk": "low",
                "risk_score": 15
            }
        ]
    }

@router.get("/alerts")
async def get_privacy_alerts():
    """Get privacy alerts"""
    return {
        "alerts": [
            {
                "id": 1,
                "type": "camera_access",
                "message": "FakeVPN accessed camera in background",
                "severity": "high",
                "timestamp": (datetime.utcnow() - timedelta(minutes=5)).isoformat()
            },
            {
                "id": 2,
                "type": "clipboard_snoop",
                "message": "App attempted to read clipboard",
                "severity": "medium",
                "timestamp": (datetime.utcnow() - timedelta(minutes=30)).isoformat()
            },
            {
                "id": 3,
                "type": "location_track",
                "message": "Background location access detected",
                "severity": "medium",
                "timestamp": (datetime.utcnow() - timedelta(hours=1)).isoformat()
            }
        ]
    }
