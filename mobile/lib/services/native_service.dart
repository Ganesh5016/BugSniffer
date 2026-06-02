import 'package:flutter/services.dart';

class NativeService {
  static const MethodChannel _channel = MethodChannel('com.bug.sniffer/native');

  static Future<Map<String, dynamic>> getHardwareMetrics() async {
    try {
      final result = await _channel.invokeMethod('getHardwareMetrics');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'cpu': 0.0, 'memory': 0.0, 'temperature': 0.0};
    }
  }

  static Future<Map<String, dynamic>> getNetworkStats() async {
    try {
      final result = await _channel.invokeMethod('getNetworkStats');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'rx_bytes': 0, 'tx_bytes': 0};
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveConnections() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getActiveConnections');
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getInstalledApps');
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
