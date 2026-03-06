// Exemples d'utilisation du OnboardingWidget
// Placez ce code dans lib/pages/onboarding_page.dart ou créez votre propre page

import 'package:flutter/material.dart';

import '../widgets/onboarding_widget.dart';

// ===================================
// EXEMPLE 1: Utilisation de base
// ===================================
class SimpleOnboardingPage extends StatelessWidget {
  const SimpleOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget();
  }
}

// ===================================
// EXEMPLE 2: Slides personnalisés
// ===================================
class CustomOnboardingPage extends StatelessWidget {
  const CustomOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      slides: [
        OnboardingSlide(
          title: '🎉 Bienvenue',
          description: 'Commencez votre aventure avec nous',
          imagePath: 'assets/images/welcome.png',
        ),
        OnboardingSlide(
          title: '🚀 Rapidité',
          description: 'Livraison en moins de 30 minutes',
          imagePath: 'assets/images/fast.png',
        ),
        OnboardingSlide(
          title: '🔒 Sécurité',
          description: 'Vos données sont protégées',
          imagePath: 'assets/images/security.png',
        ),
        OnboardingSlide(
          title: '📍 Suivi',
          description: 'Suivez votre livraison en temps réel',
          imagePath: 'assets/images/tracking.png',
        ),
      ],
      startButtonText: 'C\'est parti !',
    );
  }
}

// ===================================
// EXEMPLE 3: Sans sélection de rôle
// ===================================
class NoRoleOnboardingPage extends StatelessWidget {
  const NoRoleOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      requireRoleSelection: false,
      slides: [
        OnboardingSlide(
          title: 'Bienvenue',
          description: 'Application de livraison universelle',
          imagePath: 'assets/images/logo.png',
        ),
      ],
    );
  }
}

// ===================================
// EXEMPLE 4: Thème personnalisé
// ===================================
class ThemedOnboardingPage extends StatelessWidget {
  const ThemedOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      buttonColor: Color(0xFF1976D2),
      activeIndicatorColor: Color(0xFF64B5F6),
      inactiveIndicatorColor: Color(0xFFBDBDBD),
      startButtonText: 'Démarrer',
    );
  }
}

// ===================================
// EXEMPLE 5: Thème sombre
// ===================================
class DarkOnboardingPage extends StatelessWidget {
  const DarkOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      buttonColor: Color(0xFF1E88E5),
      activeIndicatorColor: Color(0xFF42A5F5),
      inactiveIndicatorColor: Color(0xFF424242),
    );
  }
}

// ===================================
// EXEMPLE 6: Routes personnalisées
// ===================================
class CustomRoutesOnboardingPage extends StatelessWidget {
  const CustomRoutesOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      loginRoute: '/signin',
      clientHomeRoute: '/dashboard-client',
      driverHomeRoute: '/dashboard-driver',
    );
  }
}

// ===================================
// EXEMPLE 7: Clés SharedPreferences personnalisées
// ===================================
class CustomKeysOnboardingPage extends StatelessWidget {
  const CustomKeysOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      onboardingDoneKey: 'app_intro_completed',
      selectedRoleKey: 'user_selected_role',
    );
  }
}

// ===================================
// EXEMPLE 8: Configuration complète
// ===================================
class FullConfigOnboardingPage extends StatelessWidget {
  const FullConfigOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      // Clés de stockage
      onboardingDoneKey: 'onboarding_done',
      selectedRoleKey: 'selected_role',

      // Routes
      loginRoute: '/login',
      clientHomeRoute: '/clientHome',
      driverHomeRoute: '/livreurHome',

      // Contenu
      slides: [
        OnboardingSlide(
          title: 'Bienvenue sur DEM',
          description: 'La solution de livraison la plus rapide du Sénégal',
          imagePath: 'assets/images/logo.png',
        ),
        OnboardingSlide(
          title: 'Livraison Express',
          description: 'Commandez et recevez en moins de 30 minutes',
          imagePath: 'assets/images/delivery.png',
        ),
        OnboardingSlide(
          title: 'Suivi en Direct',
          description: 'Suivez votre livreur en temps réel sur la carte',
          imagePath: 'assets/images/tracking.png',
        ),
      ],

      // Apparence
      buttonColor: Color(0xFF35CBF0),
      activeIndicatorColor: Color(0xFF33B7EB),
      inactiveIndicatorColor: Colors.grey,
      startButtonText: 'Commencer',

      // Comportement
      requireRoleSelection: true,
    );
  }
}

// ===================================
// EXEMPLE 9: Dans main.dart
// ===================================

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await setupDependencies();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery Express Mobility',
      theme: ThemeData(
        primaryColor: const Color(0xFF29B6F6),
        useMaterial3: true,
      ),
      
      // Route initiale = Splash (qui redirige vers onboarding si première fois)
      initialRoute: '/splash',
      
      routes: {
        '/splash': (context) => SplashScreenWidget(),
        '/onboarding': (context) => OnboardingWidget(),
        '/login': (context) => LoginPage(),
        '/clientHome': (context) => ClientHomePage(),
        '/livreurHome': (context) => LivreurHomePage(),
      },
    );
  }
}
*/

// ===================================
// EXEMPLE 10: Test de réinitialisation (dev)
// ===================================

/*
// Pour tester à nouveau l'onboarding en développement

class DevOnboardingResetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dev Tools')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('onboarding_done');
            await prefs.remove('selected_role');
            
            // Redémarrer l'app
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/onboarding',
              (route) => false,
            );
          },
          child: Text('Réinitialiser Onboarding'),
        ),
      ),
    );
  }
}
*/

// ===================================
// EXEMPLE 11: Vérification manuelle de l'état
// ===================================

/*
Future<void> checkOnboardingStatus() async {
  final prefs = await SharedPreferences.getInstance();
  
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final selectedRole = prefs.getString('selected_role');
  
  print('Onboarding complété: $onboardingDone');
  print('Rôle sélectionné: $selectedRole');
  
  if (onboardingDone) {
    // Utilisateur a déjà vu l'onboarding
    final storage = SecureStorageService();
    final token = await storage.getAccessToken();
    
    if (token != null) {
      print('Utilisateur connecté');
    } else {
      print('Utilisateur déconnecté');
    }
  } else {
    // Première ouverture de l'app
    print('Première ouverture');
  }
}
*/

// ===================================
// EXEMPLE 12: Slides avec icônes au lieu d'images
// ===================================

class IconOnboardingPage extends StatelessWidget {
  const IconOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Pour utiliser des icônes, vous devrez modifier le widget
    // ou créer des images PNG des icônes
    return const OnboardingWidget(
      slides: [
        OnboardingSlide(
          title: '🚚 Livraison',
          description: 'Recevez vos colis rapidement',
          imagePath: 'assets/images/delivery_icon.png',
        ),
        OnboardingSlide(
          title: '⏱️ Rapide',
          description: 'En moins de 30 minutes',
          imagePath: 'assets/images/time_icon.png',
        ),
        OnboardingSlide(
          title: '🔐 Sécurisé',
          description: 'Paiement 100% sécurisé',
          imagePath: 'assets/images/security_icon.png',
        ),
      ],
    );
  }
}

// ===================================
// EXEMPLE 13: Onboarding avec gradient background
// ===================================

class GradientOnboardingPage extends StatelessWidget {
  const GradientOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient en arrière-plan
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF29B6F6),
                Color(0xFF1976D2),
                Color(0xFF0D47A1),
              ],
            ),
          ),
        ),
        // Widget onboarding
        const OnboardingWidget(
          buttonColor: Colors.white,
          activeIndicatorColor: Colors.white,
          inactiveIndicatorColor: Colors.white54,
        ),
      ],
    );
  }
}
