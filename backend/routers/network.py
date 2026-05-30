"""Network Security Monitor API endpoints"""

from fastapi import APIRouter, HTTPException, Depends
from dependencies import get_current_user
from pydantic import BaseModel
from typing import List, Optional
import httpx
import os
import random
from datetime import datetime, timedelta

router = APIRouter()

ABUSEIPDB_KEY = os.environ.get("ABUSEIPDB_API_KEY", "")
GOOGLE_SAFE_BROWSING_KEY = os.environ.get("GOOGLE_SAFE_BROWSING_API_KEY", "")
ABUSEIPDB_BASE = "https://api.abuseipdb.com/api/v2"


class IPCheckRequest(BaseModel):
    ip_address: str


class URLCheckRequest(BaseModel):
    url: str


class NetworkScanRequest(BaseModel):
    device_id: str
    connections: List[dict]


async def check_ip_reputation(ip: str) -> dict:
    """Check IP reputation via AbuseIPDB"""
    if not ABUSEIPDB_KEY:
        return _simulate_ip_check(ip)
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{ABUSEIPDB_BASE}/check",
                params={"ipAddress": ip, "maxAgeInDays": 90},
                headers={"Key": ABUSEIPDB_KEY, "Accept": "application/json"},
                timeout=10.0
            )
            if response.status_code == 200:
                data = response.json().get("data", {})
                return {
                    "ip": ip,
                    "is_malicious": data.get("abuseConfidenceScore", 0) > 50,
                    "abuse_score": data.get("abuseConfidenceScore", 0),
                    "country": data.get("countryCode", "Unknown"),
                    "isp": data.get("isp", "Unknown"),
                    "total_reports": data.get("totalReports", 0),
                    "last_reported": data.get("lastReportedAt", "Never"),
                    "source": "AbuseIPDB"
                }
        except Exception as e:
            print(f"AbuseIPDB error: {e}")
    
    return _simulate_ip_check(ip)


def _simulate_ip_check(ip: str) -> dict:
    """Simulate IP reputation check"""
    # Make deterministic based on IP
    random.seed(hash(ip) % 10000)
    score = random.randint(0, 100)
    countries = ["US", "RU", "CN", "DE", "FR", "NL", "BR", "IN", "JP"]
    isps = [
        "Amazon AWS", "Google Cloud", "Cloudflare",
        "DigitalOcean", "OVH", "Hetzner", "Unknown ISP"
    ]
    return {
        "ip": ip,
        "is_malicious": score > 70,
        "abuse_score": score,
        "country": random.choice(countries),
        "isp": random.choice(isps),
        "total_reports": random.randint(0, 500) if score > 50 else 0,
        "last_reported": (datetime.utcnow() - timedelta(days=random.randint(1, 30))).isoformat() if score > 50 else None,
        "source": "Demo Mode - Add ABUSEIPDB_API_KEY for real data"
    }


async def check_url_safety(url: str) -> dict:
    """Check URL safety via Google Safe Browsing"""
    if not GOOGLE_SAFE_BROWSING_KEY:
        return _simulate_url_check(url)
    
    async with httpx.AsyncClient() as client:
        try:
            payload = {
                "client": {"clientId": "bugsniffer", "clientVersion": "1.0.0"},
                "threatInfo": {
                    "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
                    "platformTypes": ["ANY_PLATFORM"],
                    "threatEntryTypes": ["URL"],
                    "threatEntries": [{"url": url}]
                }
            }
            response = await client.post(
                f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={GOOGLE_SAFE_BROWSING_KEY}",
                json=payload,
                timeout=10.0
            )
            if response.status_code == 200:
                matches = response.json().get("matches", [])
                is_dangerous = len(matches) > 0
                return {
                    "url": url,
                    "is_safe": not is_dangerous,
                    "threats": [m.get("threatType") for m in matches],
                    "platform_type": matches[0].get("platformType") if matches else None,
                    "source": "Google Safe Browsing"
                }
        except Exception as e:
            print(f"Safe Browsing error: {e}")
    
    return _simulate_url_check(url)


def _simulate_url_check(url: str) -> dict:
    """Simulate URL safety check"""
    suspicious_keywords = ["phish", "bank-secure", "login-verify", "paypal-", "amazon-"]
    is_suspicious = any(kw in url.lower() for kw in suspicious_keywords)
    
    threats = []
    if is_suspicious:
        threats = ["SOCIAL_ENGINEERING"]
    
    return {
        "url": url,
        "is_safe": not is_suspicious,
        "threats": threats,
        "platform_type": "ANY_PLATFORM" if threats else None,
        "source": "Demo Mode - Add GOOGLE_SAFE_BROWSING_API_KEY for real data"
    }


@router.post("/check-ip")
async def check_ip(request: IPCheckRequest):
    """Check IP address reputation"""
    return await check_ip_reputation(request.ip_address)


@router.post("/check-url")
async def check_url(request: URLCheckRequest):
    """Check URL for phishing/malware"""
    return await check_url_safety(request.url)


@router.get("/active-connections")
async def get_active_connections(user: dict = Depends(get_current_user)):
    """Get active network connections"""
    # In a real production app, this would fetch from a database
    # For now, return real (empty) data for the new user instead of fake scary IPs
    return {
        "connections": [],
        "total": 0,
        "suspicious_count": 0,
        "timestamp": datetime.utcnow().isoformat()
    }


@router.get("/traffic-stats")
async def get_traffic_stats(user: dict = Depends(get_current_user)):
    """Get network traffic statistics"""
    return {
        "traffic_24h": [],
        "total_upload_mb": 0.0,
        "total_download_mb": 0.0,
        "blocked_connections": 0,
        "safe_connections": 0,
        "dns_queries": 0,
        "suspicious_dns": 0
    }

@router.get("/dns-requests")
async def get_dns_requests(user: dict = Depends(get_current_user)):
    """Get recent DNS requests"""
    return {
        "requests": []
    }
