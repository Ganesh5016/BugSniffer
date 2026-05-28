"""Auth router"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    email: str
    password: str
    display_name: str

@router.post("/verify-token")
async def verify_token(token: str):
    """Verify Firebase JWT token"""
    # In production, verify with Firebase Admin SDK
    return {"valid": True, "uid": "demo_user", "email": "user@example.com"}

@router.get("/profile")
async def get_profile(user_id: str = "demo"):
    return {
        "uid": user_id,
        "email": "user@bugsniffer.io",
        "display_name": "Security User",
        "devices": 2,
        "total_scans": 47,
        "threats_blocked": 12,
        "member_since": "2024-01-01",
        "plan": "Free",
        "avatar": None
    }
