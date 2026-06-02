// ============================================
// BUGSNIFFER WEB — MAIN APPLICATION
// ============================================

// --- Firebase SDK (CDN compat) ---
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, onAuthStateChanged, signOut } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';

// --- Firebase Config ---
const firebaseConfig = {
  apiKey: "AIzaSyAKkilbVzZXlJ87skcNiGyuwu93jKXQtAI",
  authDomain: "bugsniffer-51157.firebaseapp.com",
  projectId: "bugsniffer-51157",
  storageBucket: "bugsniffer-51157.firebasestorage.app",
  messagingSenderId: "675043099562",
  appId: "1:675043099562:android:0dfe55cc4516b9296261d3"
};

const fbApp = initializeApp(firebaseConfig);
const auth = getAuth(fbApp);

// --- Backend API ---
const API_BASE = 'https://bugsniffer-lxxx.onrender.com';

async function getHeaders() {
  const headers = { 'Content-Type': 'application/json' };
  const user = auth.currentUser;
  if (user) {
    const token = await user.getIdToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

async function apiGet(endpoint, retries = 2) {
  for (let i = 0; i <= retries; i++) {
    try {
      const res = await fetch(`${API_BASE}${endpoint}`, { headers: await getHeaders(), signal: AbortSignal.timeout(20000) });
      if (!res.ok) throw new Error(res.statusText);
      return await res.json();
    } catch (e) {
      console.error(`GET ${endpoint} attempt ${i + 1} failed:`, e);
      if (i < retries) await new Promise(r => setTimeout(r, 2000));
    }
  }
  return null;
}

async function apiPost(endpoint, body) {
  try {
    const res = await fetch(`${API_BASE}${endpoint}`, {
      method: 'POST',
      headers: await getHeaders(),
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(20000),
    });
    if (!res.ok) throw new Error(res.statusText);
    return await res.json();
  } catch (e) {
    console.error(`POST ${endpoint} failed:`, e);
    return null;
  }
}

// ============================================
// SCREEN MANAGEMENT
// ============================================
const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

function showScreen(id) {
  $$('.screen').forEach(s => s.classList.remove('active'));
  $(`#${id}`).classList.add('active');
}

function showPage(name) {
  $$('.page').forEach(p => p.classList.remove('active'));
  $(`#page-${name}`).classList.add('active');
  $$('.nav-link').forEach(l => l.classList.remove('active'));
  $(`.nav-link[data-page="${name}"]`)?.classList.add('active');
  $('#page-title').textContent = name.charAt(0).toUpperCase() + name.slice(1);
}

// ============================================
// AUTH
// ============================================
$('#login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = $('#login-email').value;
  const pass = $('#login-password').value;
  const err = $('#login-error');
  const btn = $('#login-btn');
  err.classList.add('hidden');
  btn.querySelector('.btn-text').textContent = 'Signing In...';
  btn.disabled = true;
  try {
    await signInWithEmailAndPassword(auth, email, pass);
  } catch (ex) {
    err.textContent = ex.message.replace('Firebase: ', '').replace(/\(.*\)/, '');
    err.classList.remove('hidden');
  }
  btn.querySelector('.btn-text').textContent = 'Sign In';
  btn.disabled = false;
});

$('#signup-btn').addEventListener('click', () => showScreen('signup-screen'));
$('#back-to-login').addEventListener('click', () => showScreen('login-screen'));

$('#signup-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = $('#signup-email').value;
  const pass = $('#signup-password').value;
  const err = $('#signup-error');
  const btn = $('#signup-submit-btn');
  err.classList.add('hidden');
  btn.querySelector('.btn-text').textContent = 'Creating...';
  btn.disabled = true;
  try {
    await createUserWithEmailAndPassword(auth, email, pass);
  } catch (ex) {
    err.textContent = ex.message.replace('Firebase: ', '').replace(/\(.*\)/, '');
    err.classList.remove('hidden');
  }
  btn.querySelector('.btn-text').textContent = 'Create Account';
  btn.disabled = false;
});

$('#logout-btn').addEventListener('click', () => signOut(auth));

// Auth state listener
onAuthStateChanged(auth, (user) => {
  if (user) {
    showScreen('app-screen');
    $('#user-email').textContent = user.email || 'User';
    $('#user-avatar').textContent = (user.email || 'U')[0].toUpperCase();
    loadDashboard();
    startPolling();
  } else {
    showScreen('login-screen');
    stopPolling();
  }
});

// ============================================
// NAVIGATION
// ============================================
$$('.nav-link').forEach(link => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    const page = link.dataset.page;
    showPage(page);
    // Load page data
    if (page === 'threats') loadThreats();
    if (page === 'scanner') loadScanHistory();
    if (page === 'network') loadNetwork();
    if (page === 'privacy') loadPrivacy();
    // Close mobile sidebar
    $('#sidebar').classList.remove('open');
  });
});

$('#mobile-menu-btn').addEventListener('click', () => {
  $('#sidebar').classList.toggle('open');
});

// ============================================
// DASHBOARD
// ============================================
let pollTimer = null;

function startPolling() {
  pollTimer = setInterval(loadDashboard, 5000);
}

function stopPolling() {
  if (pollTimer) clearInterval(pollTimer);
}

async function loadDashboard() {
  const [overview, threatsData, metrics] = await Promise.all([
    apiGet('/api/dashboard/overview'),
    apiGet('/api/threats/recent-threats'),
    apiGet('/api/dashboard/realtime-metrics'),
  ]);

  if (overview) {
    // Security score
    const score = Math.round(overview.security_score || 100);
    $('#security-score').textContent = score;
    const circumference = 326.73;
    const offset = circumference - (circumference * score / 100);
    const ring = $('#score-ring-fill');
    ring.style.strokeDashoffset = offset;
    if (score >= 80) { ring.style.stroke = 'var(--green)'; $('#score-text')?.style?.setProperty('color', 'var(--green)'); }
    else if (score >= 50) { ring.style.stroke = 'var(--gold)'; }
    else { ring.style.stroke = 'var(--red)'; }

    $('#threat-status').textContent = overview.threat_status || 'Protected';

    // Device health
    const dh = overview.device_health || {};
    updateMetric('cpu', dh.cpu_usage, '%');
    updateMetric('ram', dh.memory_usage, '%');
    updateMetric('battery', dh.battery_level, '%');
    updateMetric('temp', dh.temperature, '°C');

    // Network
    const ns = overview.network_status || {};
    $('#net-conn').textContent = ns.active_connections || 0;
    $('#net-sus').textContent = ns.suspicious_connections || 0;
  }

  if (metrics) {
    const cpu = (metrics.cpu || 0).toFixed(1);
    const mem = (metrics.memory || 0).toFixed(1);
    const bat = metrics.battery || 0;
    const temp = (metrics.temperature || 0).toFixed(1);

    updateMetric('cpu', parseFloat(cpu), '%');
    updateMetric('ram', parseFloat(mem), '%');
    updateMetric('battery', bat, '%');
    updateMetric('temp', parseFloat(temp), '°C');

    // Network speed from realtime
    const netIn = metrics.network_in || 0;
    const netOut = metrics.network_out || 0;
    $('#net-down').textContent = `${(netIn / 1024).toFixed(1)} KB/s`;
    $('#net-up').textContent = `${(netOut / 1024).toFixed(1)} KB/s`;
  }

  if (threatsData) {
    const threats = threatsData.threats || [];
    renderThreats('#threats-list', threats.slice(0, 5));
  }
}

function updateMetric(key, val, suffix) {
  val = val || 0;
  const formatted = key === 'battery' ? `${Math.round(val)}${suffix}` : `${parseFloat(val).toFixed(1)}${suffix}`;
  $(`#val-${key}`).textContent = formatted;
  $(`#pct-${key}`).textContent = formatted;

  let pct = 0;
  if (key === 'temp') pct = Math.min(100, (val / 60) * 100);
  else pct = Math.min(100, val);

  $(`#bar-${key}`).style.width = `${pct}%`;
}

// ============================================
// THREATS
// ============================================
async function loadThreats() {
  const [recent, stats] = await Promise.all([
    apiGet('/api/threats/recent-threats?limit=50'),
    apiGet('/api/threats/threat-stats'),
  ]);

  if (recent) renderThreats('#threat-history', recent.threats || []);
  if (stats) {
    $('#stat-blocked').textContent = stats.threats_blocked || 0;
    $('#stat-active').textContent = stats.malware_detected || 0;
    $('#stat-scans').textContent = stats.total_scans || 0;
  }
}

function renderThreats(containerSel, threats) {
  const container = $(containerSel);
  if (!threats.length) {
    container.innerHTML = '<div class="empty-state">✅ No threats detected</div>';
    return;
  }
  container.innerHTML = threats.map(t => {
    const risk = (t.risk_level || t.severity || 'low').toLowerCase();
    const badgeClass = risk === 'critical' ? 'badge-critical' : risk === 'high' ? 'badge-high' : risk === 'medium' ? 'badge-medium' : 'badge-low';
    const icon = risk === 'critical' || risk === 'high' ? '🔴' : risk === 'medium' ? '🟡' : '🟢';
    return `
      <div class="threat-item">
        <div class="threat-icon">${icon}</div>
        <div class="threat-info">
          <div class="threat-name">${t.app_name || t.threat_type || t.name || 'Unknown'}</div>
          <div class="threat-detail">${t.threat_category || t.description || ''} · Score: ${t.threat_score || 0}</div>
        </div>
        <span class="threat-badge ${badgeClass}">${risk.toUpperCase()}</span>
      </div>`;
  }).join('');
}

// ============================================
// SCANNER
// ============================================
$('#refresh-scans-btn').addEventListener('click', loadScanHistory);

async function loadScanHistory() {
  const data = await apiGet('/api/scanner/scan-history');
  const container = $('#scan-history');
  if (!data || !(data.history || []).length) {
    container.innerHTML = '<div class="empty-state">No scans yet. Run a Quick Scan from your mobile device.</div>';
    return;
  }
  renderThreats('#scan-history', data.history);
}

// ============================================
// NETWORK
// ============================================
$('#check-ip-btn').addEventListener('click', async () => {
  const ip = $('#ip-input').value.trim();
  if (!ip) return;
  const result = await apiPost('/api/network/check-ip', { ip_address: ip });
  const el = $('#ip-result');
  el.classList.remove('hidden', 'safe', 'danger');
  if (result) {
    const isSafe = (result.risk_score || 0) < 50;
    el.classList.add(isSafe ? 'safe' : 'danger');
    el.textContent = isSafe
      ? `✅ ${ip} — Safe (Risk: ${result.risk_score || 0}%)`
      : `⚠️ ${ip} — Suspicious (Risk: ${result.risk_score || 0}%) — ${result.threat_type || 'Unknown'}`;
  } else {
    el.classList.add('safe');
    el.textContent = `Could not check ${ip}. Backend may be waking up.`;
  }
});

async function loadNetwork() {
  const data = await apiGet('/api/network/active-connections');
  const container = $('#connections-list');
  if (!data || !(data.connections || []).length) {
    container.innerHTML = '<div class="empty-state">No active connections reported.</div>';
    return;
  }
  container.innerHTML = (data.connections || []).map(c => `
    <div class="threat-item">
      <div class="threat-icon">🔗</div>
      <div class="threat-info">
        <div class="conn-ip">${c.remote_ip || c.ip || 'Unknown'}</div>
        <div class="conn-detail">Port: ${c.remote_port || c.port || '—'} · ${c.state || c.service || ''}</div>
      </div>
      <span class="conn-status">ACTIVE</span>
    </div>
  `).join('');
}

// ============================================
// PRIVACY
// ============================================
async function loadPrivacy() {
  const data = await apiGet('/api/privacy/status');
  const container = $('#privacy-content');
  if (!data || !data.checks) {
    container.innerHTML = '<div class="empty-state">Privacy data unavailable.</div>';
    return;
  }
  container.innerHTML = (data.checks || []).map(c => {
    const status = c.status === 'safe' ? 'safe' : c.status === 'warning' ? 'warn' : 'danger';
    const icon = status === 'safe' ? '✅' : status === 'warn' ? '⚠️' : '🔴';
    return `
      <div class="privacy-item">
        <div class="priv-icon">${icon}</div>
        <div class="priv-info">
          <div class="priv-name">${c.name || 'Check'}</div>
          <div class="priv-status ${status}">${c.detail || c.status}</div>
        </div>
      </div>`;
  }).join('');
}

// ============================================
// INIT
// ============================================
showScreen('login-screen');
showPage('dashboard');
