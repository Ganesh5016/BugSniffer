// threat_monitor_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/cyber_card.dart';
import '../widgets/threat_item_widget.dart';

class ThreatMonitorScreen extends StatefulWidget {
  const ThreatMonitorScreen({super.key});
  @override
  State<ThreatMonitorScreen> createState() => _ThreatMonitorScreenState();
}

class _ThreatMonitorScreenState extends State<ThreatMonitorScreen> {
  List<dynamic> _threats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getRecentThreats();
    setState(() {
      _threats = data['threats'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF00D4FF),
      backgroundColor: const Color(0xFF111827),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                Expanded(child: _statChip('CRITICAL', _threats.where((t) => t['severity'] == 'critical').length.toString(), const Color(0xFFFF4444))),
                const SizedBox(width: 8),
                Expanded(child: _statChip('HIGH', _threats.where((t) => t['severity'] == 'high').length.toString(), const Color(0xFFFF6B00))),
                const SizedBox(width: 8),
                Expanded(child: _statChip('MEDIUM', _threats.where((t) => t['severity'] == 'medium').length.toString(), const Color(0xFFFFD700))),
                const SizedBox(width: 8),
                Expanded(child: _statChip('TOTAL', _threats.length.toString(), const Color(0xFF00D4FF))),
              ],
            ),
            const SizedBox(height: 16),

            CyberCard(
              child: Row(
                children: [
                  const _ScanningIndicator(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Engine Active', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF00FF88))),
                      const Text('Isolation Forest + Random Forest', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('DETECTED THREATS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Color(0xFF64748B), letterSpacing: 2)),
            const SizedBox(height: 8),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Color(0xFF00D4FF))))
            else if (_threats.isEmpty)
              CyberCard(child: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('✅ No threats detected', style: TextStyle(color: Color(0xFF00FF88))))))
            else
              ..._threats.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ThreatItemWidget(threat: t),
              )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontFamily: 'Orbitron', fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _ScanningIndicator extends StatefulWidget {
  const _ScanningIndicator();
  @override
  State<_ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<_ScanningIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(const Color(0xFF00FF88), const Color(0xFF00FF88).withOpacity(0.2), _ctrl.value),
          boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withOpacity(0.6), blurRadius: 8)],
        ),
      ),
    );
  }
}
