import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/screens/boot_screen.dart';
import 'src/screens/kid_home_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/parents_dashboard_screen.dart';
import 'src/screens/parents_login_screen.dart';
import 'src/services/app_storage.dart';
import 'src/state/app_controller.dart';
import 'src/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BabymodileApp());
}

class BabymodileApp extends StatefulWidget {
  const BabymodileApp({super.key});

  @override
  State<BabymodileApp> createState() => _BabymodileAppState();
}

class _BabymodileAppState extends State<BabymodileApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(storage: AppStorage());
    _controller.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppController>.value(
      value: _controller,
      child: MaterialApp(
        title: 'Babymodile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildTheme(),
        home: Consumer<AppController>(
          builder: (context, controller, _) {
            return switch (controller.view) {
              AppView.booting => const BootScreen(),
              AppView.onboarding => const OnboardingScreen(),
              AppView.kid => const KidHomeScreen(),
              AppView.parentsLogin => const ParentsLoginScreen(),
              AppView.parentsDashboard => const ParentsDashboardScreen(),
            };
          },
        ),
      ),
    );
  }
}
