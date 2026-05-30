import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _fadeController;
  late AnimationController _scanController;
  late Animation<double> _ringAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scanAnim;
  String _statusText = 'INITIALIZING...';
  double _progress = 0.0;

  final List<String> _statusMessages = [
    'LOADING THREAT DATABASE...',
    'INITIALIZING AI ENGINE...',
    'CONNECTING TO SECURITY NETWORK...',
    'CALIBRATING ANOMALY DETECTOR...',
    'SYSTEM READY',
  ];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _ringAnim = Tween<double>(begin: 0, end: 1).animate(_ringController);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanController);

    _fadeController.forward();
    _runStartupSequence();
  }

  Future<void> _runStartupSequence() async {
    for (int i = 0; i < _statusMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        _statusText = _statusMessages[i];
        _progress = (i + 1) / _statusMessages.length;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _fadeController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [Color(0xFF0A1628), Color(0xFF030712)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated rings
                SizedBox(
                  width: 180,
                  height: 180,
                  child: AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _RingPainter(_ringAnim.value),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F172A),
                              border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.5), width: 2),
                              boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                            ),
                            child: const Center(
                              child: Text('🛡️', style: TextStyle(fontSize: 40)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'BUGSNIFFER',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00D4FF),
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'AI CYBERSECURITY PLATFORM',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 48),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          color: Color(0xFF00FF88),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
                const Text(
                  'v1.0.0 · Powered by AI',
                  style: TextStyle(fontSize: 11, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00D4FF).withOpacity(0.3);

    // Outer rings
    for (int i = 0; i < 3; i++) {
      final radius = 70.0 + i * 12;
      canvas.drawCircle(center, radius, paint);
    }

    // Rotating arcs
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF00D4FF)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final radius = 70.0 + i * 12;
      final startAngle = progress * 2 * math.pi * (i % 2 == 0 ? 1 : -1) + i * math.pi / 3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi / 2,
        false,
        arcPaint..color = const Color(0xFF00D4FF).withOpacity(0.6 - i * 0.15),
      );
    }

    // Dots
    final dotPaint = Paint()..color = const Color(0xFF00FF88);
    for (int i = 0; i < 8; i++) {
      final angle = progress * 2 * math.pi + i * math.pi / 4;
      final x = center.dx + 80 * math.cos(angle);
      final y = center.dy + 80 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
