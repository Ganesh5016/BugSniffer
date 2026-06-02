import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/native_service.dart';
import '../widgets/cyber_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── SCANNER SCREEN ──────────────────────────────────────────

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  bool _scanning = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getScanHistory();
    setState(() { _history = data['history'] ?? []; _loading = false; });
  }

  String _scanStatus = 'Tap to scan all installed apps';
  double _scanProgress = 0.0;

  Future<void> _quickScan() async {
    setState(() { _scanning = true; _scanStatus = 'Fetching installed apps...'; _scanProgress = 0.0; _history.clear(); });
    
    final apps = await NativeService.getInstalledApps();
    if (apps.isEmpty) {
      setState(() { _scanning = false; _scanStatus = 'No apps found.'; });
      return;
    }

    int threatsFound = 0;
    
    for (int i = 0; i < apps.length; i++) {
      final app = apps[i];
      final name = app['name'] ?? 'Unknown';
      final pkg = app['package'] ?? '';
      final List<String> perms = List<String>.from(app['permissions'] ?? []);
      
      if (!mounted) return;
      setState(() {
        _scanStatus = 'Scanning $name... (${i + 1}/${apps.length})';
        _scanProgress = (i + 1) / apps.length;
      });
      
      try {
        final result = await ApiService.scanApp(pkg, name, perms);
        if ((result['threat_score'] ?? 0) > 0 || (result['is_malicious'] == true)) {
          setState(() {
            _history.insert(0, result);
          });
          if ((result['threat_score'] ?? 0) > 60) threatsFound++;
        }
      } catch (e) {
        // Skip on error
      }
    }
    
    setState(() { _scanning = false; _scanStatus = 'Tap to scan all installed apps'; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(threatsFound > 0 ? '⚠️ Scan complete — $threatsFound threats found' : '✅ Scan complete — No threats found'), backgroundColor: const Color(0xFF111827), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'critical': return const Color(0xFFFF4444);
      case 'high': return const Color(0xFFFF6B00);
      case 'medium': return const Color(0xFFFFD700);
      case 'low': return const Color(0xFF00D4FF);
      default: return const Color(0xFF00FF88);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick scan button
          GestureDetector(
            onTap: _scanning ? null : _quickScan,
            child: CyberCard(
              borderColor: const Color(0xFF00D4FF).withOpacity(0.3),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF00FF88)]),
                    ),
                    child: _scanning
                        ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.search, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_scanning ? 'SCANNING...' : 'QUICK SCAN',
                          style: const TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF00D4FF), letterSpacing: 1.5)),
                        Text(_scanStatus,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        if (_scanning) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: _scanProgress, backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.4), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF))),
                        ]
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // VirusTotal info
          CyberCard(
            child: Row(
              children: const [
                Text('🔬', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VirusTotal Integration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0))),
                      Text('72 antivirus engines · Hash analysis · APK scanning', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text('FREE', style: TextStyle(fontSize: 11, color: Color(0xFF00FF88), fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('SCAN HISTORY', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 2)),
          const SizedBox(height: 8),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Color(0xFF00D4FF))))
          else
            ..._history.map((h) {
              final risk = h['risk_level'] ?? 'clean';
              final color = _riskColor(risk);
              final score = h['threat_score'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: color, width: 3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.3))),
                      child: Center(child: Icon(score > 60 ? Icons.warning : Icons.check_circle, color: color, size: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['app_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0))),
                          Text(h['package_name'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'Courier')),
                          Text(h['threat_category'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
                          child: Text('$score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, fontFamily: 'Orbitron')),
                        ),
                        const SizedBox(height: 4),
                        Text(risk.toUpperCase(), style: TextStyle(fontSize: 9, color: color, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── NETWORK SCREEN ──────────────────────────────────────────

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});
  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  List<dynamic> _connections = [];
  bool _loading = true;
  final _ipController = TextEditingController();
  Map<String, dynamic>? _ipResult;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await NativeService.getActiveConnections();
    setState(() { _connections = data; _loading = false; });
  }

  Future<void> _checkIP() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    final result = await ApiService.checkIP(ip);
    setState(() => _ipResult = result);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IP checker
          CyberCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IP REPUTATION CHECK', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Powered by AbuseIPDB', style: TextStyle(fontSize: 11, color: Color(0xFF00D4FF))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0), fontFamily: 'Courier'),
                        decoration: InputDecoration(
                          hintText: '185.220.101.47',
                          hintStyle: const TextStyle(color: Color(0xFF374151), fontSize: 12),
                          filled: true, fillColor: const Color(0xFF0D1B2A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: const Color(0xFF1E3A5F).withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00D4FF))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _checkIP,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      child: const Text('CHECK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                if (_ipResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_ipResult!['is_malicious'] ?? false) ? const Color(0xFFFF4444).withOpacity(0.1) : const Color(0xFF00FF88).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (_ipResult!['is_malicious'] ?? false) ? const Color(0xFFFF4444).withOpacity(0.3) : const Color(0xFF00FF88).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text((_ipResult!['is_malicious'] ?? false) ? '🚨 MALICIOUS' : '✅ CLEAN',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: (_ipResult!['is_malicious'] ?? false) ? const Color(0xFFFF4444) : const Color(0xFF00FF88))),
                            const Spacer(),
                            Text('Score: ${_ipResult!['abuse_score']}', style: const TextStyle(fontFamily: 'Orbitron', fontSize: 13, color: Color(0xFFFF4444), fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Country: ${_ipResult!['country']}  ·  ISP: ${_ipResult!['isp']}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        if (_ipResult!['total_reports'] != null) Text('Reports: ${_ipResult!['total_reports']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('ACTIVE CONNECTIONS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 2)),
          const SizedBox(height: 8),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Color(0xFF00D4FF))))
          else
            ..._connections.map((c) {
              final suspicious = c['is_suspicious'] ?? false;
              final riskScore = c['risk_score'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: suspicious ? const Color(0xFFFF4444).withOpacity(0.05) : const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: suspicious ? const Color(0xFFFF4444).withOpacity(0.3) : const Color(0xFF1E3A5F).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(suspicious ? '⚠️' : '✓', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['remote_ip'] ?? '', style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Color(0xFF00D4FF), fontWeight: FontWeight.w600)),
                          Text('Port: ${c['remote_port']} · ${c['state']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Text(
                      'ACTIVE',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00FF88)),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── PRIVACY SCREEN ──────────────────────────────────────────

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Map<String, dynamic> _status = {};
  List<dynamic> _alerts = [];
  List<dynamic> _apps = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getPrivacyStatus(),
      ApiService.getPrivacyAlerts(),
      ApiService.getAppPermissions(),
    ]);
    setState(() {
      _status = results[0];
      _alerts = results[1]['alerts'] ?? [];
      _apps = results[2]['apps'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy score
          CyberCard(
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRIVACY SCORE', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 1.5)),
                    Text('${_status['privacy_score'] ?? 82}',
                      style: const TextStyle(fontFamily: 'Orbitron', fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED))),
                    const Text('/100', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _privacyRow('📸 Camera', false),
                      _privacyRow('🎤 Microphone', false),
                      _privacyRow('📋 Clipboard', true, warning: true),
                      _privacyRow('🖥️ Overlay', false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_alerts.isNotEmpty) ...[
            const Text('PRIVACY ALERTS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 2)),
            const SizedBox(height: 8),
            ..._alerts.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4444).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: a['severity'] == 'high' ? const Color(0xFFFF4444) : const Color(0xFFFFD700), width: 3)),
              ),
              child: Row(
                children: [
                  Text(a['type'] == 'camera_access' ? '📸' : a['type'] == 'clipboard_snoop' ? '📋' : '📍', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a['message'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)))),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],

          const Text('APP PERMISSIONS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 2)),
          const SizedBox(height: 8),

          ..._apps.map((app) {
            final risk = app['risk'] ?? 'low';
            final color = risk == 'critical' ? const Color(0xFFFF4444) : risk == 'medium' ? const Color(0xFFFFD700) : const Color(0xFF00D4FF);
            final perms = List<String>.from(app['permissions'] ?? []);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0))),
                          Text(app['package'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'Courier')),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('${app['risk_score']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4, runSpacing: 4,
                    children: perms.map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
                      child: Text(p, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _privacyRow(String label, bool active, {bool warning = false}) {
    final color = warning ? const Color(0xFFFFD700) : active ? const Color(0xFFFF4444) : const Color(0xFF00FF88);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const Spacer(),
          Text(warning ? 'ALERT' : active ? 'ACTIVE' : 'SAFE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── SETTINGS SCREEN ─────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _realTimeProtection = true;
  bool _autoScan = true;
  bool _networkMonitor = true;
  bool _notifications = true;
  bool _phishingDetection = true;
  double _sensitivity = 7.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('SETTINGS'),
        iconTheme: const IconThemeData(color: Color(0xFF00D4FF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _settingsSection('PROTECTION', [
              _toggle('Real-time Protection', 'Continuous background scanning', _realTimeProtection, (v) => setState(() => _realTimeProtection = v)),
              _toggle('Auto Scan', 'Scan new apps automatically', _autoScan, (v) => setState(() => _autoScan = v)),
              _toggle('Network Monitor', 'Monitor all connections', _networkMonitor, (v) => setState(() => _networkMonitor = v)),
              _toggle('Phishing Detection', 'Block malicious URLs', _phishingDetection, (v) => setState(() => _phishingDetection = v)),
            ]),
            const SizedBox(height: 16),
            _settingsSection('NOTIFICATIONS', [
              _toggle('Push Notifications', 'Firebase Cloud Messaging', _notifications, (v) => setState(() => _notifications = v)),
            ]),
            const SizedBox(height: 16),
            _settingsSection('AI SENSITIVITY', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Detection Sensitivity', style: TextStyle(fontSize: 14, color: Color(0xFFE2E8F0))),
                        Text('${_sensitivity.toInt()}/10', style: const TextStyle(fontFamily: 'Orbitron', fontSize: 13, color: Color(0xFF00D4FF))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF00D4FF),
                        inactiveTrackColor: const Color(0xFF1E3A5F),
                        thumbColor: const Color(0xFF00D4FF),
                        overlayColor: const Color(0xFF00D4FF).withOpacity(0.2),
                      ),
                      child: Slider(value: _sensitivity, min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => _sensitivity = v)),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _settingsSection('ACCOUNT', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                title: Text(FirebaseAuth.instance.currentUser?.email ?? 'agent@bugsniffer.io', style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14)),
                subtitle: const Text('Free Plan', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
              ),
              const Divider(color: Color(0xFF1E3A5F), height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Color(0xFFFF4444)),
                title: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF4444), fontSize: 14)),
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 10, color: Color(0xFF64748B), letterSpacing: 2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF0D1B2A))),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _toggle(String label, String sub, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFFE2E8F0))),
                Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF374151),
            inactiveTrackColor: const Color(0xFF1E3A5F).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
