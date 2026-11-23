import 'package:flutter/material.dart';

import '../services/app_sound_effects.dart';
import '../utils/device_layout.dart';

class ToyButton extends StatelessWidget {
  const ToyButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);

    final button = SizedBox(
      height: layout.buttonHeight,
      child: FilledButton.icon(
        onPressed: onPressed == null
            ? null
            : () {
                AppSoundEffects.tap();
                onPressed?.call();
              },
        icon: icon != null
            ? Icon(
                icon,
                color: const Color(0xFF26233A),
                size: layout.size(20, minScale: 0.95, maxScale: 1.05),
              )
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: TextStyle(
            color: Color(0xFF26233A),
            fontWeight: FontWeight.w800,
            fontSize: layout.size(15, minScale: 0.95, maxScale: 1.05),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          enableFeedback: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(layout.size(22)),
          ),
        ),
      ),
    );

    if (expanded) return button;
    return IntrinsicWidth(child: button);
  }
}
