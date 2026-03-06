import 'package:flutter/material.dart';

import '../widgets/onboarding_widget.dart';

/// Page Onboarding utilisant le widget réutilisable OnboardingWidget
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      onboardingDoneKey: 'hasSeenOnboarding',
      selectedRoleKey: 'selected_role',
      loginRoute: '/login',
      clientHomeRoute: '/clientHome',
      driverHomeRoute: '/livreurHome',
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
