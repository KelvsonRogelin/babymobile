import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class DeviceLayout {
  DeviceLayout._({
    required this.width,
    required this.height,
    required this.scale,
  });

  factory DeviceLayout.fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeWidth = mediaQuery.size.width - mediaQuery.padding.horizontal;
    final safeHeight = mediaQuery.size.height - mediaQuery.padding.vertical;
    final shortestSide = math.min(safeWidth, safeHeight);
    final scale = (shortestSide / 390).clamp(0.84, 1.18).toDouble();

    return DeviceLayout._(width: safeWidth, height: safeHeight, scale: scale);
  }

  final double width;
  final double height;
  final double scale;

  bool get isCompactWidth => width < 360;
  bool get isCompactHeight => height < 720;
  bool get isTablet => width >= 600;

  double size(double base, {double minScale = 0.88, double maxScale = 1.18}) {
    return (base * scale).clamp(base * minScale, base * maxScale).toDouble();
  }

  double get shellMaxWidth => isTablet ? 520 : 440;
  double get shellPadding => size(isCompactWidth ? 12 : 16);

  /// Espaço entre a borda da tela e a carcaça do telefone. Menor que o
  /// `shellPadding` para aproveitar melhor a tela e manter tudo homogêneo.
  double get shellOuterPadding => size(isCompactWidth ? 8 : 12);

  /// Espaçamento vertical padrão entre os blocos de conteúdo.
  double get contentGap =>
      size(isCompactHeight ? 10 : 14, minScale: 0.9, maxScale: 1.1);
  double get sectionRadius => size(32, minScale: 0.9, maxScale: 1.1);
  double get buttonHeight => size(isCompactHeight ? 52 : 56, maxScale: 1.1);
  double get roundButtonSize => size(isCompactHeight ? 82 : 92, maxScale: 1.1);
  double get keypadGap =>
      size(isCompactWidth ? 10 : 12, minScale: 0.9, maxScale: 1.1);
  double get displayValueFont =>
      size(isCompactWidth ? 34 : 42, minScale: 0.88, maxScale: 1.1);
  double get displayMessageFont => size(14, minScale: 0.92, maxScale: 1.08);
  double get largeTitleFont => size(22, minScale: 0.9, maxScale: 1.08);
  double get keypadDigitFont =>
      size(isCompactWidth ? 30 : 34, minScale: 0.9, maxScale: 1.05);
}
