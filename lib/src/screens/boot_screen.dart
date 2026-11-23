import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.yellow,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Icon(Icons.phone_in_talk_rounded, size: 34, color: AppTheme.ink),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Preparando o telefone...',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            SizedBox(height: 8),
            Text(
              'Só um segundinho.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
