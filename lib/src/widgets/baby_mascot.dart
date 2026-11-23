import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mascote do Babymodile: um pequeno crocodilo simpático desenhado em código.
///
/// Não depende de imagens externas, então acompanha qualquer escala de tela.
class BabyMascot extends StatelessWidget {
  const BabyMascot({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CrocodilePainter()),
    );
  }
}

class _CrocodilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (s <= 0) return;

    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect oval(double cx, double cy, double w, double h) =>
        Rect.fromCenter(center: p(cx, cy), width: w * s, height: h * s);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.mintDark;

    final headPaint = Paint()..color = AppTheme.green;
    final snoutPaint = Paint()..color = AppTheme.greenSoft;
    final whitePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = AppTheme.mintDark;
    final cheekPaint = Paint()..color = AppTheme.orange.withValues(alpha: 0.45);
    final toothPaint = Paint()..color = Colors.white;

    // ---- Espinhos do topo (ficam atrás da cabeça) ----
    final crestPaint = Paint()..color = AppTheme.green;
    final crest = Path()
      ..moveTo(0.30 * s, 0.38 * s)
      ..lineTo(0.33 * s, 0.19 * s)
      ..lineTo(0.44 * s, 0.34 * s)
      ..close()
      ..moveTo(0.44 * s, 0.34 * s)
      ..lineTo(0.50 * s, 0.13 * s)
      ..lineTo(0.57 * s, 0.34 * s)
      ..close()
      ..moveTo(0.57 * s, 0.34 * s)
      ..lineTo(0.68 * s, 0.19 * s)
      ..lineTo(0.71 * s, 0.38 * s)
      ..close();
    canvas.drawPath(crest, crestPaint);
    canvas.drawPath(crest, outline);

    // ---- Cabeça ----
    canvas.drawOval(oval(0.5, 0.55, 0.88, 0.76), headPaint);
    canvas.drawOval(oval(0.5, 0.55, 0.88, 0.76), outline);

    // ---- Focinho ----
    canvas.drawOval(oval(0.5, 0.70, 0.74, 0.36), snoutPaint);
    canvas.drawOval(oval(0.5, 0.70, 0.74, 0.36), outline);

    // ---- Narinas ----
    canvas.drawCircle(p(0.43, 0.63), s * 0.026, pupilPaint);
    canvas.drawCircle(p(0.57, 0.63), s * 0.026, pupilPaint);

    // ---- Sorriso ----
    final smile = Path()
      ..moveTo(0.33 * s, 0.72 * s)
      ..quadraticBezierTo(0.50 * s, 0.86 * s, 0.67 * s, 0.72 * s);
    canvas.drawPath(smile, outline);

    // ---- Dentinhos ----
    for (final x in const [0.39, 0.61]) {
      final tooth = Path()
        ..moveTo((x - 0.032) * s, 0.715 * s)
        ..lineTo((x + 0.032) * s, 0.715 * s)
        ..lineTo(x * s, 0.80 * s)
        ..close();
      canvas.drawPath(tooth, toothPaint);
      canvas.drawPath(tooth, outline);
    }

    // ---- Olhos ----
    canvas.drawCircle(p(0.36, 0.40), s * 0.145, whitePaint);
    canvas.drawCircle(p(0.64, 0.40), s * 0.145, whitePaint);
    canvas.drawCircle(p(0.36, 0.40), s * 0.145, outline);
    canvas.drawCircle(p(0.64, 0.40), s * 0.145, outline);

    // ---- Pupilas e brilho ----
    canvas.drawCircle(p(0.375, 0.415), s * 0.068, pupilPaint);
    canvas.drawCircle(p(0.625, 0.415), s * 0.068, pupilPaint);
    canvas.drawCircle(p(0.335, 0.355), s * 0.030, whitePaint);
    canvas.drawCircle(p(0.585, 0.355), s * 0.030, whitePaint);

    // ---- Bochechas ----
    canvas.drawCircle(p(0.185, 0.63), s * 0.082, cheekPaint);
    canvas.drawCircle(p(0.815, 0.63), s * 0.082, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant _CrocodilePainter oldDelegate) => false;
}
