import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/device_layout.dart';

/// Carcaça do telefone de brinquedo: cabeçalho opcional, visor e corpo.
class ToyPhoneShell extends StatelessWidget {
  const ToyPhoneShell({
    super.key,
    this.header,
    this.leftIcon,
    this.rightIcon,
    required this.displayLabel,
    required this.displayValue,
    required this.displayMessage,
    required this.body,
    this.scrollable = true,
  });

  /// Quando falso, a tela se ajusta à altura disponível (sem rolagem) e o
  /// corpo recebe o espaço restante, cabendo sempre na tela.
  final bool scrollable;

  /// Área livre acima do visor, usada para logotipo, mascote e saudação.
  final Widget? header;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final String displayLabel;
  final String displayValue;
  final String displayMessage;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);
    final hasTopIcons = leftIcon != null || rightIcon != null;
    final compactHeight = layout.isCompactHeight;

    final content = Container(
      decoration: BoxDecoration(
        color: AppTheme.shell,
        borderRadius: BorderRadius.circular(layout.size(38)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2D000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: EdgeInsets.all(layout.shellPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            SizedBox(height: layout.size(compactHeight ? 8 : 12)),
          ],
          if (hasTopIcons) ...[
            Row(
              children: [
                if (leftIcon != null) _TopIcon(child: leftIcon!),
                const Spacer(),
                if (rightIcon != null) _TopIcon(child: rightIcon!),
              ],
            ),
            SizedBox(height: layout.size(compactHeight ? 10 : 12)),
          ],
          Container(
            decoration: BoxDecoration(
              color: AppTheme.mintDark,
              borderRadius: BorderRadius.circular(layout.sectionRadius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: layout.size(20),
              vertical: layout.size(compactHeight ? 12 : 18),
            ),
            child: Column(
              children: [
                Text(
                  displayLabel,
                  style: TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: layout.size(12, minScale: 0.92, maxScale: 1.05),
                  ),
                ),
                SizedBox(height: layout.size(6)),
                SizedBox(
                  height: layout.size(
                    compactHeight ? 38 : 50,
                    minScale: 0.95,
                    maxScale: 1.15,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      displayValue,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppTheme.cream,
                        fontWeight: FontWeight.w900,
                        fontSize: layout.displayValueFont,
                        height: 1,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: layout.size(compactHeight ? 4 : 8)),
                Text(
                  displayMessage,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.greenSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: layout.displayMessageFont,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: layout.contentGap),
          if (scrollable) body else Expanded(child: body),
        ],
      ),
    );

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.shellMaxWidth),
          child: scrollable
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.all(layout.shellOuterPadding),
                  child: content,
                )
              : Padding(
                  padding: EdgeInsets.all(layout.shellOuterPadding),
                  child: content,
                ),
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);

    return Container(
      height: layout.size(layout.isCompactWidth ? 48 : 54),
      width: layout.size(layout.isCompactWidth ? 48 : 54),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(layout.size(20)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(child: child),
    );
  }
}
