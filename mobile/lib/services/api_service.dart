import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Change to Render URL in production
  static const Duration timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _fallback(endpoint);
    } catch (e) {
      return _fallback(endpoint);
    }
  }

  static Future<Map<String, dynamic>> _post(
    String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _fallback(endpoint);
    } catch (e) {
      return _fallback(endpoint);
    }
  }

  static Future<Map<String, dynamic>> getDashboardOverview() =>
      _get('/api/dashboard/overview');

  static Future<Map<String, dynamic>> getRealtimeMetrics() =>
      _get('/api/dashboard/realtime-metrics');

  static Future<Map<String, dynamic>> getRecentThreats() =>
      _get('/api/threats/recent-threats');

  static Future<Map<String, dynamic>> getThreatStats() =>
      _get('/api/threats/threat-stats');

  static Future<Map<String, dynamic>> getActiveConnections() =>
      _get('/api/network/active-connections');

  static Future<Map<String, dynamic>> checkIP(String ip) =>
      _post('/api/network/check-ip', {'ip_address': ip});

  static Future<Map<String, dynamic>> checkURL(String url) =>
      _post('/api/network/check-url', {'url': url});

  static Future<Map<String, dynamic>> getScanHistory() =>
      _get('/api/scanner/scan-history');

  static Future<Map<String, dynamic>> getPrivacyStatus() =>
      _get('/api/privacy/status');

  static Future<Map<String, dynamic>> getPrivacyAlerts() =>
      _get('/api/privacy/alerts');

  static Future<Map<String, dynamic>> getAppPermissions() =>
      _get('/api/privacy/app-permissions');

  // Fallback demo data
  static Map<String, dynamic> _fallback(String endpoint) {
    final r = (int min, int max) => min + (DateTime.now().millisecondsSinceEpoch % (max - min));
    
    if (endpoint.contains('overview')) {
      return {
        'security_score': 87.4,
        'active_threats': 3,
        'blocked_today': 12,
        'total_scans': 247,
        'device_health': {
          'cpu_usage': 28.5,
          'memory_usage': 54.2,
          'battery_level': 78,
          'temperature': 38.5,
        },
        'network_status': {
          'active_connections': 18,
          'suspicious_connections': 2,
          'wifi_secure': true,
        },
      };
    }
    if (endpoint.contains('realtime')) {
      return {
        'cpu': r(10, 60).toDouble(),
        'memory': r(35, 75).toDouble(),
        'battery': r(40, 100),
        'temperature': r(30, 48).toDouble(),
        'network_in': r(200, 3000),
        'network_out': r(100, 1500),
      };
    }
    if (endpoint.contains('recent-threats')) {
      return {
        'threats': [
          {'id': 't1', 'name': 'ShadowRAT.apk', 'type': 'Remote Access Trojan', 'severity': 'critical', 'threat_score': 94, 'confidence': 0.97, 'timestamp': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String()},
          {'id': 't2', 'name': 'CryptoMiner.service', 'type': 'Cryptocurrency Miner', 'severity': 'high', 'threat_score': 78, 'confidence': 0.89, 'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String()},
          {'id': 't3', 'name': 'FakeBank.apk', 'type': 'Trojan', 'severity': 'critical', 'threat_score': 91, 'confidence': 0.95, 'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
          {'id': 't4', 'name': 'Adware.popup', 'type': 'Adware', 'severity': 'medium', 'threat_score': 45, 'confidence': 0.82, 'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
        ]
      };
    }
    if (endpoint.contains('active-connections')) {
      return {
        'connections': [
          {'remote_ip': '142.250.185.78', 'service': 'Google', 'country': 'US', 'risk_score': 5, 'is_suspicious': false},
          {'remote_ip': '185.220.101.47', 'service': 'Unknown VPN', 'country': 'RU', 'risk_score': 85, 'is_suspicious': true},
          {'remote_ip': '104.244.42.65', 'service': 'Twitter/X', 'country': 'US', 'risk_score': 10, 'is_suspicious': false},
        ]
      };
    }
    if (endpoint.contains('scan-history')) {
      return {
        'history': [
          {'app_name': 'WhatsApp', 'package_name': 'com.whatsapp', 'threat_score': 8, 'risk_level': 'clean', 'threat_category': 'Clean'},
          {'app_name': 'FakeVPN Pro', 'package_name': 'com.fakevpn.pro', 'threat_score': 88, 'risk_level': 'critical', 'threat_category': 'Spyware'},
          {'app_name': 'Chrome', 'package_name': 'com.android.chrome', 'threat_score': 5, 'risk_level': 'clean', 'threat_category': 'Clean'},
        ]
      };
    }
    if (endpoint.contains('privacy/status')) {
      return {'location_apps': 6, 'privacy_score': 82, 'camera_in_use': false, 'microphone_in_use': false};
    }
    if (endpoint.contains('privacy/alerts')) {
      return {
        'alerts': [
          {'type': 'camera_access', 'message': 'FakeVPN accessed camera in background', 'severity': 'high', 'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
          {'type': 'clipboard_snoop', 'message': 'App attempted to read clipboard', 'severity': 'medium', 'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String()},
        ]
      };
    }
    if (endpoint.contains('app-permissions')) {
      return {
        'apps': [
          {'name': 'Unknown VPN', 'package': 'com.fakevpn.pro', 'permissions': ['READ_SMS', 'BIND_ACCESSIBILITY_SERVICE', 'RECORD_AUDIO'], 'risk': 'critical', 'risk_score': 88},
          {'name': 'WhatsApp', 'package': 'com.whatsapp', 'permissions': ['CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS'], 'risk': 'medium', 'risk_score': 35},
        ]
      };
    }
    return {};
  }
}
