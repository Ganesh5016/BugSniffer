import 'package:flutter/material.dart';

class ThreatItemWidget extends StatelessWidget {
  final Map<String, dynamic> threat;
  const ThreatItemWidget({super.key, required this.threat});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return const Color(0xFFFF4444);
      case 'high': return const Color(0xFFFF6B00);
      case 'medium': return const Color(0xFFFFD700);
      case 'low': return const Color(0xFF00D4FF);
      default: return const Color(0xFF00FF88);
    }
  }

  String _timeAgo(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final diff = DateTime.now().difference(DateTime.parse(timestamp));
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return 'Unknown'; }
  }

  @override
  Widget build(BuildContext context) {
    final severity = threat['severity'] ?? 'low';
    final score = threat['threat_score'] ?? 0;
    final color = _severityColor(severity);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  threat['name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
                ),
                Text(
                  threat['type'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  score.toString(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, fontFamily: 'Orbitron'),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _timeAgo(threat['timestamp']),
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
