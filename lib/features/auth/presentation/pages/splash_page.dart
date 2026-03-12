// lib/pages/splash_page.dart
import 'package:delivery_express_mobility_frontend/features/client/navigation/client_routes.dart';
import 'package:delivery_express_mobility_frontend/features/driver_moto/navigation/driver_moto_routes.dart';
import 'package:delivery_express_mobility_frontend/widgets/splash_screen_widget.dart';
import 'package:flutter/material.dart';

/// Page Splash utilisant le widget réutilisable SplashScreenWidget
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreenWidget(
      onboardingRoute: '/onboarding',
      loginRoute: '/login',
      clientHomeRoute: ClientRoutes.home,
      driverHomeRoute: DriverMotoRoutes.home,
      logoPath: 'assets/images/logoo.png',
      animationDuration: 2000,
    );
  }
}
