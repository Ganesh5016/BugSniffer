// BugSniffer API Service
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' }
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('bugsniffer_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Dashboard
export const getDashboardOverview = (userId = 'demo') =>
  api.get(`/api/dashboard/overview?user_id=${userId}`).then(r => r.data);

export const getRealtimeMetrics = () =>
  api.get('/api/dashboard/realtime-metrics').then(r => r.data);

// Threats
export const getRecentThreats = (userId = 'demo', limit = 10) =>
  api.get(`/api/threats/recent-threats?user_id=${userId}&limit=${limit}`).then(r => r.data);

export const getThreatStats = () =>
  api.get('/api/threats/threat-stats').then(r => r.data);

export const analyzeProcess = (processData) =>
  api.post('/api/threats/analyze-process', processData).then(r => r.data);

export const scanDevice = (scanRequest) =>
  api.post('/api/threats/scan-device', scanRequest).then(r => r.data);

// APK Scanner
export const scanApp = (appData) =>
  api.post('/api/scanner/scan-app', appData).then(r => r.data);

export const checkHash = (hash) =>
  api.post(`/api/scanner/check-hash?file_hash=${hash}`).then(r => r.data);

export const getScanHistory = (userId = 'demo') =>
  api.get(`/api/scanner/scan-history?user_id=${userId}`).then(r => r.data);

// Network
export const checkIP = (ip) =>
  api.post('/api/network/check-ip', { ip_address: ip }).then(r => r.data);

export const checkURL = (url) =>
  api.post('/api/network/check-url', { url }).then(r => r.data);

export const getActiveConnections = (deviceId = 'demo') =>
  api.get(`/api/network/active-connections?device_id=${deviceId}`).then(r => r.data);

export const getTrafficStats = () =>
  api.get('/api/network/traffic-stats').then(r => r.data);

export const getDNSRequests = () =>
  api.get('/api/network/dns-requests').then(r => r.data);

// Privacy
export const getPrivacyStatus = (deviceId = 'demo') =>
  api.get(`/api/privacy/status?device_id=${deviceId}`).then(r => r.data);

export const getAppPermissions = () =>
  api.get('/api/privacy/app-permissions').then(r => r.data);

export const getPrivacyAlerts = () =>
  api.get('/api/privacy/alerts').then(r => r.data);

// User
export const getUserProfile = (userId = 'demo') =>
  api.get(`/api/auth/profile?user_id=${userId}`).then(r => r.data);

export default api;
