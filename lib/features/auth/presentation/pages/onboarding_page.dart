import 'package:delivery_express_mobility_frontend/features/client/navigation/client_routes.dart';
import 'package:delivery_express_mobility_frontend/features/driver_moto/navigation/driver_moto_routes.dart';
import 'package:delivery_express_mobility_frontend/widgets/onboarding_widget.dart';
import 'package:flutter/material.dart';

/// Page Onboarding utilisant le widget réutilisable OnboardingWidget
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      onboardingDoneKey: 'hasSeenOnboarding',
      selectedRoleKey: 'selected_role',
      loginRoute: '/login',
      clientHomeRoute: ClientRoutes.home,
      driverHomeRoute: DriverMotoRoutes.home,
      slides: [
        OnboardingSlide(
          title: 'Bienvenue !',
          description: 'Livraison rapide et sécurisée à Dakar',
          imagePath: 'assets/images/logo.png',
        ),
      ],
      buttonColor: Color(0xFF35CBF0),
      activeIndicatorColor: Color(0xFF33B7EB),
      startButtonText: 'Commencer',
      requireRoleSelection: false,
    );
  }
}
