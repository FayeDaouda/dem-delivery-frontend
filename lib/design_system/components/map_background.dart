/// 🗺️ Full-screen Map Background with Animated Pin
import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class MapBackground extends StatefulWidget {
  const MapBackground({super.key});

  @override
  State<MapBackground> createState() => _MapBackgroundState();
}

class _MapBackgroundState extends State<MapBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _pinController;
  late Animation<double> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _pinController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pinAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Gradient background (simulating map)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DEMColors.gradientDark1,
                  DEMColors.gradientDark2,
                ],
              ),
            ),
            child: CustomPaint(
              painter: _MapLinesPainter(),
              child: Container(),
            ),
          ),

          // Animated location pin
          Positioned(
            left: MediaQuery.of(context).size.width * 0.35,
            top: MediaQuery.of(context).size.height * 0.35,
            child: AnimatedBuilder(
              animation: _pinAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_pinAnimation.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulse ring
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DEMColors.mapPin.withValues(
                                alpha: 0.3 - (_pinAnimation.value / 100)),
                            width: 2,
                          ),
                        ),
                      ),
                      // Pin icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DEMColors.mapPin,
                          boxShadow: [
                            BoxShadow(
                              color: DEMColors.mapPin.withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6E6B4A).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final boldPaint = Paint()
      ..color = const Color(0xFF8E8A5C).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Map lines
    final path1 = Path()
      ..moveTo(0, size.height * 0.08)
      ..lineTo(size.width * 0.28, size.height * 0.15)
      ..lineTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width, size.height * 0.2);

    final path2 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.35)
      ..lineTo(size.width * 0.33, size.height * 0.28)
      ..lineTo(size.width * 0.55, size.height * 0.38)
      ..lineTo(size.width * 0.84, size.height * 0.3);

    final path3 = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.57)
      ..lineTo(size.width * 0.75, size.height * 0.53)
      ..lineTo(size.width, size.height * 0.6);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, boldPaint);
    canvas.drawPath(path3, paint);

    for (double y = 0.1; y < 0.72; y += 0.12) {
      final p = Path()
        ..moveTo(size.width * 0.08, size.height * y)
        ..lineTo(size.width * 0.22, size.height * (y + 0.06))
        ..lineTo(size.width * 0.4, size.height * (y + 0.02))
        ..lineTo(size.width * 0.56, size.height * (y + 0.08));
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
