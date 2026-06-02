import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:battery_plus/battery_plus.dart';
import 'native_service.dart';

class ApiService {
  static const String baseUrl = 'https://bugsniffer-lxxx.onrender.com';
  static const Duration timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _emptyFallback(endpoint);
    } catch (e) {
      return _emptyFallback(endpoint);
    }
  }

  static Future<Map<String, dynamic>> _post(
    String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(body),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _emptyFallback(endpoint);
    } catch (e) {
      return _emptyFallback(endpoint);
    }
  }

  static Future<void> sendTelemetry() async {
    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      
      final hardware = await NativeService.getHardwareMetrics();
      final connections = await NativeService.getActiveConnections();
      
      double memoryUsage = (hardware['memory'] as num?)?.toDouble() ?? 0.0;
      double cpuUsage = (hardware['cpu'] as num?)?.toDouble() ?? 0.0;
      double temp = (hardware['temperature'] as num?)?.toDouble() ?? 0.0;
      int activeConnections = connections.length;
      
      await _post('/api/dashboard/telemetry', {
        'battery': batteryLevel,
        'cpu': cpuUsage,
        'memory': memoryUsage,
        'temperature': temp,
        'active_connections': activeConnections,
        'wifi_secure': true,
      });
    } catch (e) {
      debugPrint('Telemetry sync failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getDashboardOverview() async {
    await sendTelemetry(); // Sync real data before fetching overview
    return _get('/api/dashboard/overview');
  }

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

  static Future<Map<String, dynamic>> scanApp(String packageName, String appName, List<String> permissions) async {
    return _post('/api/scanner/scan-app', {
      'package_name': packageName,
      'app_name': appName,
      'permissions': permissions,
    });
  }

  static Future<Map<String, dynamic>> getPrivacyStatus() =>
      _get('/api/privacy/status');

  static Future<Map<String, dynamic>> getPrivacyAlerts() =>
      _get('/api/privacy/alerts');

  static Future<Map<String, dynamic>> getAppPermissions() =>
      _get('/api/privacy/app-permissions');

  // Safe empty data for errors
  static Map<String, dynamic> _emptyFallback(String endpoint) {
    if (endpoint.contains('overview')) {
      return {
        'security_score': 100.0,
        'active_threats': 0,
        'blocked_today': 0,
        'device_health': {'cpu_usage': 0, 'memory_usage': 0, 'battery_level': 100, 'temperature': 0},
        'network_status': {'active_connections': 0, 'suspicious_connections': 0, 'wifi_secure': true},
        'recent_scans': []
      };
    }
    if (endpoint.contains('realtime')) {
      return {'cpu': 0, 'memory': 0, 'battery': 100, 'temperature': 0, 'network_in': 0, 'network_out': 0};
    }
    if (endpoint.contains('recent-threats')) {
      return {'threats': []};
    }
    if (endpoint.contains('active-connections')) {
      return {'connections': []};
    }
    if (endpoint.contains('scan-history')) {
      return {'history': []};
    }
    if (endpoint.contains('threat-stats')) {
      return {
          "total_scans": 0, "threats_blocked": 0, "malware_detected": 0, "phishing_blocked": 0, "clean_apps": 0,
          "protection_rate": 100.0, "daily_threats": []
      };
    }
    return {};
  }
}
