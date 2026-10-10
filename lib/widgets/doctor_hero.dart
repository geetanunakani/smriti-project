import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Animated hero for the login screen:
///  - gradient plum background with soft glow
///  - floating medical icons (plus, pill, heart, syringe, mic...)
///  - pulsing heart-monitor logo with heartbeat ripples
///  - ECG line that draws itself continuously
class DoctorHero extends StatefulWidget {
  const DoctorHero({super.key});

  @override
  State<DoctorHero> createState() => _DoctorHeroState();
}

class _DoctorHeroState extends State<DoctorHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // One 6s loop. Heartbeat = 4 beats per loop, ECG = 1 sweep per loop,
    // floaters use integer speeds so the loop is seamless.
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _floaters = <_Floater>[
    _Floater(Icons.add_rounded, 0.08, 0.14, 30, 0.00, 1),
    _Floater(Icons.medication_rounded, 0.82, 0.12, 28, 0.25, 1),
    _Floater(Icons.favorite_rounded, 0.90, 0.42, 22, 0.60, 2),
    _Floater(Icons.vaccines_rounded, 0.06, 0.45, 26, 0.45, 1),
    _Floater(Icons.mic_rounded, 0.70, 0.30, 20, 0.80, 2),
    _Floater(Icons.medical_services_rounded, 0.24, 0.26, 22, 0.10, 2),
    _Floater(Icons.add_rounded, 0.55, 0.08, 18, 0.70, 1),
    _Floater(Icons.science_rounded, 0.16, 0.66, 20, 0.35, 1),
    _Floater(Icons.health_and_safety_rounded, 0.80, 0.66, 22, 0.05, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SmritiColors.plumDeep, SmritiColors.plum, Color(0xFF6B1F47)],
        ),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // soft glow behind logo
                Positioned(
                  left: w / 2 - 170,
                  top: h * 0.02,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        SmritiColors.rose.withOpacity(0.32),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // floating medical icons
                for (final f in _floaters)
                  Positioned(
                    left: w * f.x + math.sin(2 * math.pi * (t * f.speed + f.phase)) * 10,
                    top: h * f.y + math.cos(2 * math.pi * (t * f.speed + f.phase)) * 14,
                    child: Transform.rotate(
                      angle: math.sin(2 * math.pi * (t * f.speed + f.phase)) * 0.25,
                      child: Icon(
                        f.icon,
                        size: f.size,
                        color: SmritiColors.roseLight.withOpacity(0.22),
                      ),
                    ),
                  ),

                // logo + text
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        children: [
                          _PulsingLogo(t: t),
                          const SizedBox(height: 12),
                          const Text(
                            'S M R I T I',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'From what is heard — to what is remembered.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: SmritiColors.petal.withOpacity(0.9),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ECG line
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 44,
                  height: 44,
                  child: CustomPaint(painter: _EcgPainter(progress: t)),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _Floater {
  final IconData icon;
  final double x, y, size, phase;
  final int speed;
  const _Floater(this.icon, this.x, this.y, this.size, this.phase, this.speed);
}

class _PulsingLogo extends StatelessWidget {
  final double t;
  const _PulsingLogo({required this.t});

  @override
  Widget build(BuildContext context) {
    // 4 heartbeats per loop
    final beatPhase = (t * 4) % 1.0;
    // sharp "lub-dub" style pulse
    final pulse = math.pow(math.max(0, math.sin(beatPhase * math.pi * 2)), 3).toDouble();
    final scale = 1 + 0.09 * pulse;

    return SizedBox(
      width: 130,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ripple(beatPhase),
          _ripple((beatPhase + 0.5) % 1.0),
          Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD65A88), SmritiColors.rose],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.85), width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: SmritiColors.rose.withOpacity(0.35 + 0.35 * pulse),
                    blurRadius: 18 + 16 * pulse,
                    spreadRadius: 2 + 4 * pulse,
                  ),
                ],
              ),
              child: const Icon(Icons.monitor_heart_rounded,
                  color: Colors.white, size: 42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ripple(double p) {
    return Opacity(
      opacity: (1 - p) * 0.55,
      child: Container(
        width: 80 + 50 * p,
        height: 80 + 50 * p,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: SmritiColors.roseLight, width: 1.6),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double progress; // 0..1
  _EcgPainter({required this.progress});

  Path _buildPath(Size s) {
    final midY = s.height / 2;
    final amp = s.height * 0.48;
    final beatW = s.width / 2;
    final p = Path()..moveTo(0, midY);
    for (var i = 0; i < 2; i++) {
      final x = i * beatW;
      p.lineTo(x + beatW * 0.10, midY);
      p.quadraticBezierTo(x + beatW * 0.15, midY - 8, x + beatW * 0.20, midY); // P
      p.lineTo(x + beatW * 0.28, midY);
      p.lineTo(x + beatW * 0.31, midY + 8); // Q
      p.lineTo(x + beatW * 0.36, midY - amp); // R
      p.lineTo(x + beatW * 0.41, midY + amp * 0.6); // S
      p.lineTo(x + beatW * 0.45, midY);
      p.lineTo(x + beatW * 0.55, midY);
      p.quadraticBezierTo(x + beatW * 0.63, midY - 12, x + beatW * 0.71, midY); // T
      p.lineTo(x + beatW, midY);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    final metric = path.computeMetrics().first;
    final len = metric.length;

    // faint full line
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.10),
    );

    // bright moving segment
    final head = progress * len * 1.35;
    final end = math.min(len, head);
    final start = math.max(0.0, head - len * 0.38);
    if (end <= start) return;
    final seg = metric.extractPath(start, end);

    canvas.drawPath(
      seg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = SmritiColors.rose.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      seg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = SmritiColors.petal,
    );

    if (head < len) {
      final tan = metric.getTangentForOffset(end);
      if (tan != null) {
        canvas.drawCircle(tan.position, 4, Paint()..color = Colors.white);
        canvas.drawCircle(
          tan.position,
          9,
          Paint()..color = SmritiColors.roseLight.withOpacity(0.35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) => old.progress != progress;
}