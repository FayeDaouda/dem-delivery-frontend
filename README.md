# Delivery Express Mobility Frontend

Projet Flutter structuré avec architecture Clean + BLoC pour une application mobile moderne.

## 🎯 Widgets Réutilisables

### ✅ SplashScreenWidget
Widget d'écran de démarrage avec animation du logo et vérification JWT.
- 📁 `lib/widgets/splash_screen_widget.dart`
- 📖 [Documentation](docs/SPLASH_SCREEN_WIDGET.md)
- �� [Exemples](lib/widgets/splash_screen_widget_examples.dart)

### ✅ OnboardingWidget
Widget d'introduction avec vérification de première ouverture.
- 📁 `lib/widgets/onboarding_widget.dart`
- 📖 [Documentation](docs/ONBOARDING_WIDGET.md)
- 🎯 [Exemples](lib/widgets/onboarding_widget_examples.dart)

📚 **[Guide complet des widgets](WIDGETS_GUIDE.md)**

## 📦 Structure
```
lib/
├── core/
│   ├── di/              # Injection de dépendances (GetIt)
│   ├── services/        # Services partagés (WebSocket, etc.)
│   └── storage/         # Stockage sécurisé
├── features/
│   ├── auth/           # Feature Authentification (BLoC)
│   ├── deliveries/     # Feature Livraisons (BLoC)
│   └── passes/         # Feature Passes (Cubit)
├── pages/              # Pages principales
├── widgets/            # Widgets réutilisables ✨
├── themes/             # Thèmes et styles
└── models/             # Modèles de données
```

## 🚀 Démarrage rapide
```bash
# 1. Installer les dépendances
flutter pub get

# 2. Lancer l'app
flutter run

# 3. Exécuter les tests
flutter test
```

## 📚 Documentation

### Architecture
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture détaillée
- [QUICK_START.md](QUICK_START.md) - Guide de démarrage
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Guide de migration
- [SUMMARY.md](SUMMARY.md) - Résumé complet

### Widgets
- [WIDGETS_GUIDE.md](WIDGETS_GUIDE.md) - Guide des widgets réutilisables
- [SPLASH_WIDGET_SUMMARY.md](SPLASH_WIDGET_SUMMARY.md) - SplashScreen
- [ONBOARDING_WIDGET_SUMMARY.md](ONBOARDING_WIDGET_SUMMARY.md) - Onboarding

### API
- [docs/api/](docs/api/) - Documentation des endpoints

## 🔧 Configuration

### Backend API
```dart
// lib/core/di/service_locator.dart
baseUrl: "https://dem-delivery-backend.onrender.com"
```

### Tokens
Gérés automatiquement par `SecureStorageService` et injectés via intercepteur Dio.

## 📱 Plateformes
- ✅ Android
- ✅ iOS
- ⏳ Web (futur)

---
**Architecture**: Clean Architecture + BLoC Pattern  
**Date**: 4 Mars 2026
