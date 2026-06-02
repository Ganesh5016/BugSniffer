"""
BugSniffer Backend API - FastAPI Application
Production-ready cybersecurity platform backend
"""

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
import uvicorn
import os
from routers import threats, scanner, network, auth, dashboard, privacy
from services.firebase_service import init_firebase

app = FastAPI(
    title="BugSniffer API",
    description="AI-powered cybersecurity platform backend",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase
@app.on_event("startup")
async def startup_event():
    init_firebase()

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(threats.router, prefix="/api/threats", tags=["Threat Detection"])
app.include_router(scanner.router, prefix="/api/scanner", tags=["APK Scanner"])
app.include_router(network.router, prefix="/api/network", tags=["Network Monitor"])
app.include_router(privacy.router, prefix="/api/privacy", tags=["Privacy Protection"])

@app.get("/")
async def root():
    return {
        "name": "BugSniffer API",
        "version": "1.0.0",
        "status": "operational",
        "endpoints": "/api/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "BugSniffer Backend"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 8000)),
        reload=os.environ.get("ENV", "production") == "development"
    )
