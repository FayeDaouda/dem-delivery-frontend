# OnboardingWidget - Documentation

## 📖 Description

Widget réutilisable pour l'Onboarding de l'application DEM avec vérification de première ouverture.

## ✨ Fonctionnalités

✅ **Vérification première ouverture** - Détecte si l'app a déjà été ouverte  
✅ **Navigation intelligente** :
- Première fois → Affiche l'onboarding
- Onboarding déjà vu + token valide → Home (selon rôle)
- Onboarding déjà vu + pas de token → Login

✅ **Sélection de rôle** - Client ou Driver  
✅ **Slides personnalisables** - Contenu configurable  
✅ **Animation pulsante** - Bouton avec effet visuel  
✅ **Responsive** - S'adapte aux tablettes et téléphones  
✅ **Gestion d'erreurs** - Fallback automatique

## 📍 Emplacement

```
lib/
└── widgets/
    └── onboarding_widget.dart
```

## 🎯 Utilisation

### Utilisation basique

```dart
import 'package:flutter/material.dart';
import '../widgets/onboarding_widget.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget();
  }
}
```

### Utilisation avec slides personnalisés

```dart
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingWidget(
      slides: [
        OnboardingSlide(
          title: 'Bienvenue !',
          description: 'Découvrez notre application',
          imagePath: 'assets/images/welcome.png',
        ),
        OnboardingSlide(
          title: 'Livraisons rapides',
          description: 'Recevez vos colis en un temps record',
          imagePath: 'assets/images/delivery.png',
        ),
        OnboardingSlide(
          title: 'Sécurité garantie',
          description: 'Vos données sont protégées',
          imagePath: 'assets/images/security.png',
        ),
      ],
      buttonColor: Color(0xFF35CBF0),
      startButtonText: 'Commencer',
    );
  }
}
```

### Configuration complète

```dart
OnboardingWidget(
  onboardingDoneKey: 'onboarding_done',
  selectedRoleKey: 'selected_role',
  loginRoute: '/login',
  clientHomeRoute: '/clientHome',
  driverHomeRoute: '/livreurHome',
  slides: [...], // Vos slides personnalisés
  buttonColor: Color(0xFF35CBF0),
  activeIndicatorColor: Color(0xFF33B7EB),
  inactiveIndicatorColor: Colors.grey,
  startButtonText: 'Commencer',
  requireRoleSelection: true,
)
```

## 🔧 Paramètres configurables

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `onboardingDoneKey` | `String` | `'onboarding_done'` | Clé SharedPreferences pour onboarding |
| `selectedRoleKey` | `String` | `'selected_role'` | Clé pour le rôle sélectionné |
| `loginRoute` | `String` | `'/login'` | Route vers le login |
| `clientHomeRoute` | `String` | `'/clientHome'` | Route home client |
| `driverHomeRoute` | `String` | `'/livreurHome'` | Route home driver |
| `slides` | `List<OnboardingSlide>` | `[]` (slides par défaut) | Liste des slides |
| `buttonColor` | `Color?` | `Color(0xFF35CBF0)` | Couleur du bouton |
| `activeIndicatorColor` | `Color?` | `Color(0xFF33B7EB)` | Couleur indicateur actif |
| `inactiveIndicatorColor` | `Color?` | `Colors.grey` | Couleur indicateur inactif |
| `startButtonText` | `String` | `'Commencer'` | Texte du bouton |
| `requireRoleSelection` | `bool` | `true` | Activer la sélection de rôle |

## 🔄 Flux de navigation

```
┌──────────────────┐
│ OnboardingWidget │
└────────┬─────────┘
         │
         ▼
  Onboarding déjà vu ?
         │
    ┌────┴────┐
    │         │
   OUI       NON
    │         │
    │         └──────► Afficher Onboarding
    │                 (+ Sélection rôle si activé)
    │                          │
    │                          ▼
    │                 Marquer comme complété
    │                          │
    │                          └──────► Login
    │
    ▼
  Token JWT existe ?
         │
    ┌────┴────┐
    │         │
   OUI       NON
    │         │
    │         └──────────────────────► Login
    │
    ▼
 Récupérer rôle
    │
 ┌──┴───┐
 │      │
CLIENT DRIVER
 │      │
 ▼      ▼
Home  Home
Client Driver
```

## 📱 Modèle OnboardingSlide

```dart
class OnboardingSlide {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
```

### Exemple de slides

```dart
const slides = [
  OnboardingSlide(
    title: 'Bienvenue !',
    description: 'Découvrez notre application de livraison',
    imagePath: 'assets/images/welcome.png',
  ),
  OnboardingSlide(
    title: 'Livraison rapide',
    description: 'Recevez vos colis en moins de 30 minutes',
    imagePath: 'assets/images/fast.png',
  ),
  OnboardingSlide(
    title: 'Suivi en temps réel',
    description: 'Suivez votre livraison en direct',
    imagePath: 'assets/images/tracking.png',
  ),
];
```

## 🎨 Personnalisation visuelle

### Thème clair

```dart
OnboardingWidget(
  buttonColor: Color(0xFF2196F3),
  activeIndicatorColor: Color(0xFF1976D2),
  inactiveIndicatorColor: Colors.grey[300],
)
```

### Thème sombre

```dart
OnboardingWidget(
  buttonColor: Color(0xFF1E88E5),
  activeIndicatorColor: Color(0xFF64B5F6),
  inactiveIndicatorColor: Colors.grey[700],
)
```

### Sans sélection de rôle

```dart
OnboardingWidget(
  requireRoleSelection: false,
)
```

## 🛡️ Gestion des erreurs

| Situation | Comportement |
|-----------|--------------|
| Erreur lecture SharedPreferences | Affiche l'onboarding |
| Image manquante | Affiche icône de secours |
| Token invalide | Redirige vers Login |
| Rôle invalide | Redirige vers Login |
| Widget démonté | Vérifie `mounted` avant navigation |

## 🧪 Test de réinitialisation

Pour tester à nouveau l'onboarding (développement) :

```dart
// Supprimer les données SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.remove('onboarding_done');
await prefs.remove('selected_role');

// Relancer l'app
```

## 📱 Responsive Design

Le widget s'adapte automatiquement :
- **Tablettes (> 600px)** : Images 250x250, texte plus grand
- **Téléphones (≤ 600px)** : Images 180x180, texte normal

## 🎬 Animations

### Animation Pulse (Bouton)
- **Amplitude** : 0.95 → 1.05
- **Durée** : 1 seconde
- **Mode** : Répétition avec inversion

### Animation Page Indicator
- **Durée** : 300ms
- **Type** : AnimatedContainer
- **Propriétés** : Largeur (12px → 24px)

## 🔗 Dépendances

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
```

## 🧪 Tests

### Test de première ouverture

```dart
testWidgets('Affiche onboarding à la première ouverture', (tester) async {
  // Arrange - Simuler première ouverture
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_done');

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: OnboardingWidget(),
    ),
  );

  await tester.pumpAndSettle();

  // Assert
  expect(find.byType(PageView), findsOneWidget);
});
```

### Test de navigation après onboarding vu

```dart
testWidgets('Redirige vers login si onboarding déjà vu', (tester) async {
  // Arrange
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_done', true);

  // Mock SecureStorage sans token
  final mockStorage = MockSecureStorageService();
  when(mockStorage.getAccessToken()).thenAnswer((_) async => null);

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: OnboardingWidget(),
      routes: {
        '/login': (context) => Scaffold(body: Text('Login')),
      },
    ),
  );

  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Login'), findsOneWidget);
});
```

## 💡 Cas d'usage

### 1. Première installation
```
User ouvre l'app → Onboarding s'affiche → Sélection rôle → Slides → Login
```

### 2. Utilisateur déconnecté
```
User ouvre l'app → Onboarding skip → Login s'affiche
```

### 3. Utilisateur connecté
```
User ouvre l'app → Onboarding skip → Token valide → Home (selon rôle)
```

## 🚀 Intégration dans le projet

Le widget est déjà intégré :

1. ✅ Widget créé : `lib/widgets/onboarding_widget.dart`
2. ✅ Page refactorisée : `lib/pages/onboarding_page.dart`
3. ✅ Modèle créé : `OnboardingSlide`
4. ✅ Navigation configurée dans `main.dart`

## 📝 Changelog

### v1.0.0 (4 Mars 2026)
- ✨ Création du widget réutilisable
- ✨ Vérification première ouverture
- ✨ Navigation intelligente
- ✨ Sélection de rôle
- ✨ Slides personnalisables
- ✨ Animation pulsante
- ✨ Support responsive
- ✨ Gestion d'erreurs complète

## 🎯 Prochaines améliorations

- [ ] Support Lottie animations
- [ ] Indicateurs de progression personnalisés
- [ ] Bouton "Passer" sur les slides
- [ ] Support multilingue
- [ ] Thèmes prédéfinis
- [ ] Sauvegarde de la page vue
- [ ] Analytics integration

## 👨‍💻 Auteur

Delivery Express Mobility - Frontend Team  
Date: 4 Mars 2026

## 📄 Licence

Propriétaire - Delivery Express Mobility
