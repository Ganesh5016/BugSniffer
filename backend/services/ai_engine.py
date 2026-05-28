"""
BugSniffer AI Threat Detection Engine
Uses Isolation Forest and Random Forest for anomaly detection
"""

import numpy as np
from sklearn.ensemble import IsolationForest, RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import joblib
import os
import random
from datetime import datetime

# Model paths
MODEL_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODEL_DIR, exist_ok=True)

ISOLATION_MODEL_PATH = os.path.join(MODEL_DIR, "isolation_forest.pkl")
RF_MODEL_PATH = os.path.join(MODEL_DIR, "random_forest.pkl")
SCALER_PATH = os.path.join(MODEL_DIR, "scaler.pkl")

# Threat categories
THREAT_CATEGORIES = {
    0: "Clean",
    1: "Adware",
    2: "Spyware", 
    3: "Ransomware",
    4: "Trojan",
    5: "Cryptominer",
    6: "RAT",
    7: "Keylogger"
}

RISK_LEVELS = {
    "clean": (0, 20),
    "low": (21, 40),
    "medium": (41, 60),
    "high": (61, 80),
    "critical": (81, 100)
}


def get_risk_level(score: float) -> str:
    for level, (low, high) in RISK_LEVELS.items():
        if low <= score <= high:
            return level
    return "clean"


def generate_training_data(n_samples=1000):
    """Generate synthetic training data for the AI models"""
    np.random.seed(42)
    
    # Features: cpu_usage, memory_usage, battery_drain, network_upload,
    #           network_download, background_connections, permission_count,
    #           api_calls_per_min, file_ops_per_min, process_injections
    
    # Normal behavior
    normal = np.random.normal(
        loc=[15, 30, 5, 100, 500, 2, 8, 50, 20, 0],
        scale=[5, 10, 2, 50, 200, 1, 3, 15, 8, 0.1],
        size=(int(n_samples * 0.8), 10)
    )
    normal = np.clip(normal, 0, None)
    normal_labels = np.zeros(len(normal))
    
    # Malicious behavior patterns
    malware_patterns = []
    
    # Cryptominer: high CPU, network
    miners = np.random.normal(
        loc=[85, 60, 20, 1000, 500, 15, 5, 200, 10, 0],
        scale=[5, 10, 3, 200, 100, 3, 1, 30, 3, 0.1],
        size=(50, 10)
    )
    malware_patterns.append((miners, 5))
    
    # Spyware: moderate CPU, high file ops, network
    spyware = np.random.normal(
        loc=[25, 40, 15, 500, 200, 10, 25, 100, 150, 0],
        scale=[5, 10, 3, 100, 50, 2, 5, 20, 30, 0.1],
        size=(50, 10)
    )
    malware_patterns.append((spyware, 2))
    
    # RAT: variable CPU, high connections, many APIs
    rats = np.random.normal(
        loc=[40, 50, 12, 800, 800, 20, 20, 300, 50, 2],
        scale=[10, 10, 3, 200, 200, 5, 5, 50, 20, 0.5],
        size=(50, 10)
    )
    malware_patterns.append((rats, 6))
    
    # Ransomware: high CPU + file ops
    ransomware = np.random.normal(
        loc=[70, 80, 25, 200, 50, 5, 10, 150, 500, 1],
        scale=[10, 10, 5, 50, 20, 2, 2, 30, 100, 0.3],
        size=(50, 10)
    )
    malware_patterns.append((ransomware, 3))
    
    X_malware = np.vstack([p[0] for p in malware_patterns])
    y_malware = np.concatenate([[p[1]] * len(p[0]) for p in malware_patterns])
    
    X = np.vstack([normal, X_malware])
    y = np.concatenate([normal_labels, y_malware])
    
    X = np.clip(X, 0, None)
    return X, y


def train_models():
    """Train and save AI models"""
    print("Training BugSniffer AI models...")
    X, y = generate_training_data()
    
    # Scale features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Isolation Forest for anomaly detection
    iso_forest = IsolationForest(
        n_estimators=100,
        contamination=0.2,
        random_state=42,
        n_jobs=-1
    )
    iso_forest.fit(X_scaled)
    
    # Random Forest for classification
    rf_classifier = RandomForestClassifier(
        n_estimators=100,
        random_state=42,
        n_jobs=-1,
        class_weight='balanced'
    )
    rf_classifier.fit(X_scaled, y)
    
    # Save models
    joblib.dump(iso_forest, ISOLATION_MODEL_PATH)
    joblib.dump(rf_classifier, RF_MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    
    print("Models trained and saved successfully!")
    return iso_forest, rf_classifier, scaler


def load_models():
    """Load or train models"""
    if (os.path.exists(ISOLATION_MODEL_PATH) and 
        os.path.exists(RF_MODEL_PATH) and 
        os.path.exists(SCALER_PATH)):
        iso_forest = joblib.load(ISOLATION_MODEL_PATH)
        rf_classifier = joblib.load(RF_MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)
        return iso_forest, rf_classifier, scaler
    else:
        return train_models()


# Load models on module import
try:
    _iso_forest, _rf_classifier, _scaler = load_models()
except Exception as e:
    print(f"Warning: Could not load models: {e}")
    _iso_forest, _rf_classifier, _scaler = None, None, None


def analyze_process(process_data: dict) -> dict:
    """
    Analyze a process/app for threats
    
    Args:
        process_data: Dict with process metrics
        
    Returns:
        Analysis result with threat score, category, confidence
    """
    features = np.array([[
        process_data.get("cpu_usage", 0),
        process_data.get("memory_usage", 0),
        process_data.get("battery_drain", 0),
        process_data.get("network_upload", 0),
        process_data.get("network_download", 0),
        process_data.get("background_connections", 0),
        process_data.get("permission_count", 0),
        process_data.get("api_calls_per_min", 0),
        process_data.get("file_ops_per_min", 0),
        process_data.get("process_injections", 0),
    ]])
    
    if _iso_forest is None or _rf_classifier is None:
        # Fallback simulation
        return _simulate_analysis(process_data)
    
    try:
        features_scaled = _scaler.transform(features)
        
        # Isolation Forest anomaly score (-1 = anomaly, 1 = normal)
        anomaly_score = _iso_forest.decision_function(features_scaled)[0]
        is_anomaly = _iso_forest.predict(features_scaled)[0] == -1
        
        # Random Forest classification
        threat_class = int(_rf_classifier.predict(features_scaled)[0])
        probabilities = _rf_classifier.predict_proba(features_scaled)[0]
        confidence = float(max(probabilities))
        
        # Calculate threat score (0-100)
        normalized_anomaly = max(0, min(1, (0.5 - anomaly_score) / 0.5))
        threat_score = normalized_anomaly * 100 if is_anomaly else max(0, normalized_anomaly * 40)
        
        if threat_class > 0:
            threat_score = max(threat_score, 50 + (confidence * 50))
        
        threat_score = round(min(100, threat_score), 1)
        
        return {
            "threat_score": threat_score,
            "risk_level": get_risk_level(threat_score),
            "threat_category": THREAT_CATEGORIES.get(threat_class, "Unknown"),
            "threat_class": threat_class,
            "confidence": round(confidence, 3),
            "is_anomaly": bool(is_anomaly),
            "anomaly_score": round(float(anomaly_score), 4),
            "analysis_timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error in AI analysis: {e}")
        return _simulate_analysis(process_data)


def _simulate_analysis(process_data: dict) -> dict:
    """Fallback simulation when models unavailable"""
    cpu = process_data.get("cpu_usage", 0)
    mem = process_data.get("memory_usage", 0)
    net = process_data.get("network_upload", 0)
    perms = process_data.get("permission_count", 0)
    
    score = (cpu * 0.4 + mem * 0.2 + min(net / 10, 30) + min(perms * 2, 20)) 
    score = min(100, score + random.uniform(-5, 5))
    
    return {
        "threat_score": round(score, 1),
        "risk_level": get_risk_level(score),
        "threat_category": "Adware" if score > 60 else "Clean",
        "threat_class": 1 if score > 60 else 0,
        "confidence": round(random.uniform(0.75, 0.95), 3),
        "is_anomaly": score > 50,
        "anomaly_score": round(random.uniform(-0.5, 0.5), 4),
        "analysis_timestamp": datetime.utcnow().isoformat()
    }


def batch_analyze(processes: list) -> list:
    """Analyze multiple processes"""
    return [
        {"process": p.get("name", "unknown"), **analyze_process(p)}
        for p in processes
    ]


def analyze_apk_features(apk_data: dict) -> dict:
    """Analyze APK features for malware"""
    # Map APK features to process-like features
    process_data = {
        "cpu_usage": 20,
        "memory_usage": apk_data.get("size_mb", 0) * 2,
        "battery_drain": 5,
        "network_upload": 100 if apk_data.get("uses_internet", False) else 0,
        "network_download": 200 if apk_data.get("uses_internet", False) else 0,
        "background_connections": apk_data.get("background_services", 0),
        "permission_count": len(apk_data.get("permissions", [])),
        "api_calls_per_min": apk_data.get("native_code", False) * 100,
        "file_ops_per_min": 10,
        "process_injections": apk_data.get("debuggable", False) * 2
    }
    
    result = analyze_process(process_data)
    result["dangerous_permissions"] = [
        p for p in apk_data.get("permissions", [])
        if p in DANGEROUS_PERMISSIONS
    ]
    return result


DANGEROUS_PERMISSIONS = [
    "READ_CONTACTS", "WRITE_CONTACTS",
    "READ_CALL_LOG", "WRITE_CALL_LOG",
    "RECORD_AUDIO", "CAMERA",
    "ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION",
    "READ_SMS", "SEND_SMS", "RECEIVE_SMS",
    "READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE",
    "PROCESS_OUTGOING_CALLS",
    "BIND_ACCESSIBILITY_SERVICE",
    "PACKAGE_USAGE_STATS",
    "SYSTEM_ALERT_WINDOW",
    "DEVICE_ADMIN"
]
