import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../widgets/cyber_card.dart';
import '../widgets/threat_item_widget.dart';
import '../widgets/metric_gauge.dart';
import 'threat_monitor_screen.dart';
import 'scanner_screen.dart';
import 'network_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _metrics = {};
  List<dynamic> _threats = [];
  bool _loading = true;
  Timer? _metricsTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _metricsTimer = Timer.periodic(const Duration(seconds: 4), (_) => _updateMetrics());
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      ApiService.getDashboardOverview(),
      ApiService.getRecentThreats(),
      ApiService.getRealtimeMetrics(),
    ]);
    setState(() {
      _overview = results[0];
      _threats = (results[1]['threats'] ?? []);
      _metrics = results[2];
      _loading = false;
    });
  }

  Future<void> _updateMetrics() async {
    final m = await ApiService.getRealtimeMetrics();
    if (mounted) setState(() => _metrics = m);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const ThreatMonitorScreen(),
      const ScannerScreen(),
      const NetworkScreen(),
      const PrivacyScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('BUGSNIFFER'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                _PulseDot(),
                SizedBox(width: 6),
                Text('LIVE', style: TextStyle(fontSize: 10, color: Color(0xFF00FF88), fontWeight: FontWeight.w700, letterSpacing: 1)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF00D4FF),
          unselectedItemColor: const Color(0xFF374151),
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.warning_amber_outlined), activeIcon: Icon(Icons.warning_amber), label: 'Threats'),
            BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search), label: 'Scanner'),
            BottomNavigationBarItem(icon: Icon(Icons.wifi_outlined), activeIcon: Icon(Icons.wifi), label: 'Network'),
            BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Privacy'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
    }

    final score = (_overview['security_score'] ?? 87.4) as num;
    final threats = (_overview['active_threats'] ?? 3) as int;
    final blocked = (_overview['blocked_today'] ?? 12) as int;
    final health = _overview['device_health'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF111827),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security score hero
            CyberCard(
              child: Row(
                children: [
                  // Ring gauge
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: MetricGauge(
                      value: score.toDouble(),
                      maxValue: 100,
                      label: 'SCORE',
                      color: score >= 80 ? const Color(0xFF00FF88) : score >= 60 ? const Color(0xFFFFD700) : const Color(0xFFFF4444),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: score >= 80 ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
                                boxShadow: [BoxShadow(color: (score >= 80 ? const Color(0xFF00FF88) : const Color(0xFFFF4444)).withOpacity(0.5), blurRadius: 6)]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              score >= 80 ? 'PROTECTED' : 'AT RISK',
                              style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700, color: score >= 80 ? const Color(0xFF00FF88) : const Color(0xFFFF4444), letterSpacing: 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _quickStat('Active Threats', threats.toString(), const Color(0xFFFF4444)),
                        _quickStat('Blocked Today', blocked.toString(), const Color(0xFF00D4FF)),
                        _quickStat('Scans Done', (_overview['total_scans'] ?? 247).toString(), const Color(0xFF00FF88)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Real-time metrics
            const _SectionTitle('DEVICE METRICS'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _metricCard('CPU', '${(_metrics['cpu'] ?? 28).toStringAsFixed(1)}%', const Color(0xFF00D4FF), Icons.memory)),
                const SizedBox(width: 8),
                Expanded(child: _metricCard('RAM', '${(_metrics['memory'] ?? 54).toStringAsFixed(1)}%', const Color(0xFFFFD700), Icons.storage_outlined)),
                const SizedBox(width: 8),
                Expanded(child: _metricCard('BATTERY', '${_metrics['battery'] ?? 78}%', const Color(0xFF00FF88), Icons.battery_charging_full)),
                const SizedBox(width: 8),
                Expanded(child: _metricCard('TEMP', '${(_metrics['temperature'] ?? 38).toStringAsFixed(0)}°C', const Color(0xFFFF6B00), Icons.thermostat)),
              ],
            ),

            const SizedBox(height: 16),

            // Resource bars
            CyberCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('RESOURCE USAGE'),
                  const SizedBox(height: 12),
                  _resourceBar('CPU Usage', (_metrics['cpu'] ?? 28.5) / 100, const Color(0xFF00D4FF)),
                  const SizedBox(height: 10),
                  _resourceBar('Memory', (_metrics['memory'] ?? 54.2) / 100, const Color(0xFFFFD700)),
                  const SizedBox(height: 10),
                  _resourceBar('Battery', (_metrics['battery'] ?? 78) / 100, const Color(0xFF00FF88)),
                  const SizedBox(height: 10),
                  _resourceBar('Temperature', (_metrics['temperature'] ?? 38.5) / 80, const Color(0xFFFF6B00)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Network
            CyberCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('NETWORK'),
                        const SizedBox(height: 8),
                        _networkStat('↓ Download', '${((_metrics['network_in'] ?? 1200) / 1024).toStringAsFixed(1)} KB/s', const Color(0xFF00D4FF)),
                        _networkStat('↑ Upload', '${((_metrics['network_out'] ?? 400) / 1024).toStringAsFixed(1)} KB/s', const Color(0xFF00FF88)),
                        _networkStat('Connections', '${_overview['network_status']?['active_connections'] ?? 18}', Colors.white),
                        _networkStat('Suspicious', '${_overview['network_status']?['suspicious_connections'] ?? 2}', const Color(0xFFFF4444)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D1B2A),
                      border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (_overview['network_status']?['wifi_secure'] ?? true) ? Icons.wifi : Icons.wifi_off,
                          color: (_overview['network_status']?['wifi_secure'] ?? true) ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
                          size: 24,
                        ),
                        Text(
                          (_overview['network_status']?['wifi_secure'] ?? true) ? 'SECURE' : 'UNSAFE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: (_overview['network_status']?['wifi_secure'] ?? true) ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recent threats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle('RECENT THREATS'),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF00D4FF))),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_threats.isEmpty)
              CyberCard(
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('✅ No threats detected', style: TextStyle(color: Color(0xFF00FF88), fontSize: 14)),
                  ),
                ),
              )
            else
              ..._threats.take(4).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ThreatItemWidget(threat: t),
              )),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, fontFamily: 'Orbitron')),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _resourceBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            Text('${(value * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontFamily: 'Orbitron', color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _networkStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, fontFamily: 'Courier')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 2, fontWeight: FontWeight.w600),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(const Color(0xFF00FF88), const Color(0xFF00FF88).withOpacity(0.3), _ctrl.value),
          boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withOpacity(0.5 * (1 - _ctrl.value)), blurRadius: 4)],
        ),
      ),
    );
  }
}
