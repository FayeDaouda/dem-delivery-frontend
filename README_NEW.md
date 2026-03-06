# Delivery Express Mobility - Frontend Flutter

Application mobile moderne pour gestion de livraisons, VTC futur et système de passes/commissions.

## 🏗️ Architecture

Nous utilisons une **Clean Architecture** avec le **BLoC Pattern** pour une séparation nette des responsabilités:

```
lib/
├── core/
│   ├── di/             → Injection de dépendances (GetIt)
│   ├── services/       → Services partagés (WebSocket, etc.)
│   └── storage/        → Persistance locale
│
├── features/           → Domaine métier
│   ├── auth/          → Authentification
│   ├── deliveries/    → Gestion livraisons
│   └── passes/        → Passes & commissions
│
└── pages/             → UI Pages (Stateless + BLoC)
```

**Avantages:**
- ✅ Testabilité complète
- ✅ Découplage UI ↔ Logique
- ✅ Évolutif (VTC, API changes)
- ✅ WebSocket intégré
- ✅ Injection de dépendances

## 📖 Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Explication complète de l'architecture
- **[MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)** - Guide pour migrer les pages existantes

## 🚀 Démarrage rapide

### Installation
```bash
flutter pub get
```

### Dépendances clés
```yaml
flutter_bloc: ^8.1.3      # Gestion d'état
get_it: ^7.6.0            # Service locator
equatable: ^2.0.5         # Comparaison d'objets
dio: ^5.9.1               # Client HTTP
web_socket_channel: ^2.4.5 # WebSocket
```

### Lancer l'app
```bash
flutter run
```

## 🔄 Flux de données

```
User Interaction (UI)
        ↓
    BLoC Event
        ↓
   Use Case
        ↓
  Repository
        ↓
  Data Source (API)
        ↓
   Backend
```

## 🔌 Service Locator (GetIt)

Toutes les dépendances sont injectées automatiquement:

```dart
// Utiliser dans BLoC
context.read<AuthBloc>()

// Utiliser ailleurs
getIt<DeliveriesBloc>()
```

## 🌐 WebSocket - Temps réel

```dart
final socket = getIt<SocketService>();
await socket.connect(wsUrl, accessToken);

socket.events.listen((event) {
  if (event.type == WebSocketEventType.deliveryAssigned) {
    // Actualiser les livraisons
  }
});
```

## ✅ Feature Checklist

### Auth ✅
- [x] LoginUseCase
- [x] AuthBloc
- [x] AuthRepository
- [x] Refactorisation LoginPage

### Deliveries ✅
- [x] FetchDeliveriesUseCase
- [x] DeliveriesBloc
- [x] DeliveriesRepository
- [ ] Migration ClientHomePage (TODO)

### Passes ✅
- [x] ActivatePassUseCase
- [x] PassesCubit
- [x] PassesRepository
- [ ] Migration PassesPage (TODO)

### WebSocket ✅
- [x] SocketService
- [x] Événements temps réel
- [ ] Intégration dans pages (TODO)

## 🧪 Tests

Structure des tests:
```
test/
├── bloc_test_example.dart    # Exemples de tests BLoC
└── ... (plus de tests à ajouter)
```

Lancer les tests:
```bash
flutter test
```

## 🔧 Configuration

### API Backend
URL de base: `https://dem-delivery-backend.onrender.com`

Configurable dans `lib/core/di/service_locator.dart`:
```dart
final dio = Dio(
  BaseOptions(
    baseUrl: "https://dem-delivery-backend.onrender.com",
    ...
  ),
);
```

### Tokens
Automatiquement gérés par le StorageService et injectés dans les requêtes via intercepteur Dio.

## 📱 Plateformes supportées

- ✅ Android
- ✅ iOS
- ⏳ Web (futur)

## 🚀 Prochaines étapes

1. Migrer ClientHomePage vers DeliveriesBloc
2. Migrer LivreurHomePage + WebSocket
3. Migrer PassesPage vers PassesCubit
4. Ajouter tests unitaires complètes
5. Intégration WebSocket temps réel
6. Feature VTC

## 📚 Ressources

- [BLoC Library](https://bloclibrary.dev/)
- [Clean Architecture](https://resocoder.com/flutter-clean-architecture)
- [GetIt Documentation](https://pub.dev/packages/get_it)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)

## 🤝 Contribution

- Suivre le pattern BLoC/Clean Architecture
- Créer des tests pour toute nouvelle feature
- Documenter les changements architecturaux

## 📞 Support

Pour des questions sur l'architecture:
- Voir [ARCHITECTURE.md](./ARCHITECTURE.md)
- Voir [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)

---

**Dernière mise à jour:** 4 Mars 2026
**Version Architecture:** 2.0 (BLoC + Clean Architecture)
