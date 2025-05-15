import 'package:flutter/material.dart';

class LegalScalesIcon extends StatelessWidget {
  final double size;
  final Color color;

  const LegalScalesIcon({
    super.key,
    this.size = 50.0,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ScalesPainter(color: color),
      ),
    );
  }
}

class ScalesPainter extends CustomPainter {
  final Color color;

  ScalesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Base stand
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height),
      paint,
    );

    // Top horizontal bar
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.3),
      paint,
    );

    // Left scale thread
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.2, size.height * 0.6),
      paint,
    );

    // Right scale thread
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.6),
      paint,
    );

    // Left scale dish
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      size.width * 0.15,
      paint,
    );

    // Right scale dish
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.15,
      paint,
    );

    // Top ornament
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.2),
      size.width * 0.05,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Updated LogoHeader to use the new icon
class LogoHeader extends StatelessWidget {
  final String subtitle;

  const LogoHeader({
    super.key,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      decoration: const BoxDecoration(
        color: Color(0xFFE6E6E6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          // Legal scales icon
          const LegalScalesIcon(
            size: 50,
            color: Colors.black,
          ),
          const SizedBox(height: 8),
          
          // LEGAL WEB title
          const Text(
            'LEGAL WEB',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37), // Golden color
            ),
          ),
          const SizedBox(height: 4),
          
          // Subtitle text
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}