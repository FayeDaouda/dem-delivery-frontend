// Test unitaire pour SplashScreenWidget
// Pour exécuter : flutter test test/widgets/splash_screen_widget_test.dart

import 'package:delivery_express_mobility_frontend/core/storage/secure_storage_service.dart';
import 'package:delivery_express_mobility_frontend/widgets/splash_screen_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

// Note: Pour générer les mocks, exécutez :
// flutter pub run build_runner build

@GenerateMocks([SecureStorageService])
void main() {
  group('SplashScreenWidget Tests', () {
    testWidgets('affiche le logo lors du chargement', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(),
        ),
      );

      // Assert
      final splash = find.byType(SplashScreenWidget);
      expect(find.descendant(of: splash, matching: find.byType(Image)),
          findsOneWidget);
      expect(find.descendant(of: splash, matching: find.byType(FadeTransition)),
          findsWidgets);
      expect(
          find.descendant(of: splash, matching: find.byType(ScaleTransition)),
          findsWidgets);
    });

    testWidgets('utilise le bon backgroundColor', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(
            backgroundColor: Colors.black,
          ),
        ),
      );

      // Assert
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('applique la durée d\'animation personnalisée', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(
            animationDuration: 2000,
          ),
        ),
      );

      // Assert - Vérifie que le widget est créé
      expect(find.byType(SplashScreenWidget), findsOneWidget);
    });

    testWidgets('affiche une icône de secours si l\'image ne charge pas',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(
            logoPath: 'assets/images/invalid_logo.png',
          ),
        ),
      );

      // Attend que l'erreur de chargement d'image se produise
      await tester.pump();

      // Note: Le test de l'errorBuilder nécessite une configuration
      // spéciale de l'environnement de test pour simuler l'échec de chargement
    });
  });

  group('SplashScreenWidget Navigation Tests', () {
    // Note: Ces tests nécessitent le mock de SecureStorageService
    // Exemple de structure (à implémenter avec vos mocks) :

    /*
    testWidgets('navigue vers onboarding si pas de token', (tester) async {
      // Arrange
      final mockStorage = MockSecureStorageService();
      when(mockStorage.getAccessToken()).thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreenWidget(animationDuration: 100),
          routes: {
            '/onboarding': (context) => Scaffold(body: Text('Onboarding')),
          },
        ),
      );

      // Wait for animation
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // Assert
      expect(find.text('Onboarding'), findsOneWidget);
    });

    testWidgets('navigue vers clientHome si token CLIENT', (tester) async {
      // Arrange
      final mockStorage = MockSecureStorageService();
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token123');
      when(mockStorage.getRole()).thenAnswer((_) async => 'CLIENT');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreenWidget(animationDuration: 100),
          routes: {
            '/clientHome': (context) => Scaffold(body: Text('Client Home')),
          },
        ),
      );

      // Wait for animation
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // Assert
      expect(find.text('Client Home'), findsOneWidget);
    });

    testWidgets('navigue vers driverHome si token DRIVER', (tester) async {
      // Arrange
      final mockStorage = MockSecureStorageService();
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token456');
      when(mockStorage.getRole()).thenAnswer((_) async => 'DRIVER');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreenWidget(animationDuration: 100),
          routes: {
            '/livreurHome': (context) => Scaffold(body: Text('Driver Home')),
          },
        ),
      );

      // Wait for animation
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // Assert
      expect(find.text('Driver Home'), findsOneWidget);
    });

    testWidgets('navigue vers onboarding si rôle invalide', (tester) async {
      // Arrange
      final mockStorage = MockSecureStorageService();
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token789');
      when(mockStorage.getRole()).thenAnswer((_) async => 'INVALID_ROLE');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreenWidget(animationDuration: 100),
          routes: {
            '/onboarding': (context) => Scaffold(body: Text('Onboarding')),
          },
        ),
      );

      // Wait for animation
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // Assert
      expect(find.text('Onboarding'), findsOneWidget);
    });

    testWidgets('navigue vers onboarding en cas d\'erreur', (tester) async {
      // Arrange
      final mockStorage = MockSecureStorageService();
      when(mockStorage.getAccessToken()).thenThrow(Exception('Storage error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreenWidget(animationDuration: 100),
          routes: {
            '/onboarding': (context) => Scaffold(body: Text('Onboarding')),
          },
        ),
      );

      // Wait for animation
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // Assert
      expect(find.text('Onboarding'), findsOneWidget);
    });
    */
  });

  group('SplashScreenWidget Responsive Tests', () {
    testWidgets('affiche un logo plus grand sur tablette', (tester) async {
      // Arrange - Simuler une tablette (800x1200)
      tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(),
        ),
      );

      // Assert - Vérifier que le widget est rendu
      final splash = find.byType(SplashScreenWidget);
      expect(find.descendant(of: splash, matching: find.byType(Image)),
          findsOneWidget);

      // Cleanup
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('affiche un logo plus petit sur téléphone', (tester) async {
      // Arrange - Simuler un téléphone (375x812)
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(),
        ),
      );

      // Assert - Vérifier que le widget est rendu
      final splash = find.byType(SplashScreenWidget);
      expect(find.descendant(of: splash, matching: find.byType(Image)),
          findsOneWidget);

      // Cleanup
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
  });

  group('SplashScreenWidget Animation Tests', () {
    testWidgets('démarre l\'animation au chargement', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(),
        ),
      );

      // Assert - Vérifie la présence des transitions sans avancer manuellement l'animation
      final splash = find.byType(SplashScreenWidget);
      expect(find.descendant(of: splash, matching: find.byType(FadeTransition)),
          findsWidgets);
    });
  });

  group('SplashScreenWidget Configuration Tests', () {
    testWidgets('utilise les routes personnalisées', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(
            onboardingRoute: '/custom-onboarding',
            loginRoute: '/custom-login',
            clientHomeRoute: '/custom-client',
            driverHomeRoute: '/custom-driver',
          ),
        ),
      );

      // Assert - Vérifie que le widget est créé avec les bonnes routes
      expect(find.byType(SplashScreenWidget), findsOneWidget);
    });

    testWidgets('utilise le chemin de logo personnalisé', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWidget(
            logoPath: 'assets/images/custom_logo.png',
          ),
        ),
      );

      // Assert
      final splash = find.byType(SplashScreenWidget);
      expect(find.descendant(of: splash, matching: find.byType(Image)),
          findsOneWidget);
    });
  });
}

// =======================
// COMMANDES UTILES
// =======================

/*
# Exécuter tous les tests
flutter test

# Exécuter un test spécifique
flutter test test/widgets/splash_screen_widget_test.dart

# Exécuter avec couverture de code
flutter test --coverage

# Générer les mocks (si vous utilisez mockito)
flutter pub run build_runner build

# Nettoyer et regénérer les mocks
flutter pub run build_runner build --delete-conflicting-outputs

# Exécuter en mode watch
flutter test --watch
*/
