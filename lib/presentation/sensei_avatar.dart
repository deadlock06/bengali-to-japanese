// The sensei — the same painted teacher used in the AI Classroom, reusable so
// the "explain" popup and floating button show the identical character.
import 'package:flutter/material.dart';

class SenseiAvatar extends StatelessWidget {
  const SenseiAvatar({super.key, this.size = 64, this.accent = const Color(0xFF4D7DF7)});
  final double size;
  final Color accent;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size, height: size * 78 / 64,
        child: CustomPaint(painter: _SenseiPainter(accent)),
      );
}

class _SenseiPainter extends CustomPainter {
  _SenseiPainter(this.accent);
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 146);
    final robe = Path()
      ..moveTo(28, 140)..quadraticBezierTo(28, 86, 60, 86)
      ..quadraticBezierTo(92, 86, 92, 140)..close();
    canvas.drawPath(robe, Paint()..color = const Color(0xFF242424));
    canvas.drawPath(robe, Paint()..color = const Color(0xFF2E2E2E)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final scarf = Path()..moveTo(40, 100)..quadraticBezierTo(60, 110, 80, 100);
    canvas.drawPath(scarf, Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(60, 60), 25, Paint()..color = const Color(0xFFF2D9BE));
    final hair = Path()
      ..moveTo(35, 56)..quadraticBezierTo(35, 32, 60, 32)..quadraticBezierTo(85, 32, 85, 56)
      ..quadraticBezierTo(76, 42, 60, 42)..quadraticBezierTo(44, 42, 35, 56)..close();
    canvas.drawPath(hair, Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(const Offset(60, 28), 9, Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(const Offset(60, 21), 3.5, Paint()..color = accent);
    final ink = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(const Offset(51, 60), 2.6, ink);
    canvas.drawCircle(const Offset(69, 60), 2.6, ink);
    final smile = Path()..moveTo(53, 70)..quadraticBezierTo(60, 75, 67, 70);
    canvas.drawPath(smile, Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SenseiPainter old) => old.accent != accent;
}
