// lib/pages/splash_page.dart
import 'package:flutter/material.dart';

import '../widgets/splash_screen_widget.dart';

/// Page Splash utilisant le widget réutilisable SplashScreenWidget
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreenWidget(
      onboardingRoute: '/onboarding',
      loginRoute: '/login',
      clientHomeRoute: '/clientHome',
      driverHomeRoute: '/livreurHome',
      logoPath: 'assets/images/logo.png',
      animationDuration: 1500,
    );
  }
}
