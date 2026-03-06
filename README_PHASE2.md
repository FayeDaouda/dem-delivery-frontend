# 🚗 Delivery Express Mobility - Frontend

Application mobile Flutter moderne avec architecture Clean Architecture, BLoC pattern, et intégration WebSocket pour fonctionnalités temps réel.

---

## 📋 Table des matières

- [Aperçu](#aperçu)
- [Architecture](#architecture)
- [Fonctionnalités](#fonctionnalités)
- [Installation](#installation)
- [Démarrage rapide](#démarrage-rapide)
- [Documentation](#documentation)
- [Tests](#tests)
- [Performance](#performance)

---

## 🎯 Aperçu

**Delivery Express Mobility** est une plateforme complète pour la gestion de livraisons avec deux rôles principaux:

- **Clients** : Suivi de leurs livraisons
- **Conducteurs** : Gestion des livraisons assignées en temps réel

### Technologies clés
- **Framework**: Flutter 3.7.0+
- **State Management**: BLoC + Cubit
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Real-time**: WebSocket
- **Cache**: Hive local database
- **DI**: GetIt service locator

---

## 🏗️ Architecture

### Clean Architecture
```
Domain Layer (Business Logic)
├── Entities
├── Repositories (Interfaces)
└── Use Cases

Data Layer (Data Management)
├── Models
├── DataSources (Remote + Local)
└── Repository Implementations

Presentation Layer (UI)
├── BLoCs (Complex state)
├── Cubits (Simple state)
├── Pages
└── Widgets
```

### Dépendances clés
```yaml
flutter_bloc: ^8.1.3        # State management
get_it: ^7.6.0             # Service locator
dio: ^5.9.1                # HTTP client
web_socket_channel: ^2.4.5 # WebSocket
hive: ^2.2.3               # Local cache
bloc_test: ^9.1.0          # Testing
mockito: ^5.4.4            # Mocking
```

---

## ✨ Fonctionnalités

### Phase 1: Architecture ✅
- ✅ AuthBloc avec JWT
- ✅ DeliveriesBloc
- ✅ PassesCubit
- ✅ Service locator (GetIt)
- ✅ WebSocket service

### Phase 2: Pages & Tests ✅
- ✅ ClientHomePage (BLoC + pull-to-refresh)
- ✅ LivreurHomePage (WebSocket + real-time)
- ✅ 23+ unit tests
- ✅ Integration test templates
- ✅ Hive cache layer
- ✅ Offline mode
- ✅ Performance guide

---

## 📁 Structure

```
lib/
├── features/
│   ├── auth/
│   ├── deliveries/
│   │   └── data/datasources/deliveries_local_data_source.dart
│   └── passes/
├── core/
│   ├── di/service_locator.dart
│   ├── services/socket_service.dart
│   └── storage/
├── pages/
│   ├── login_page_bloc.dart ✅
│   ├── client_home_page_bloc.dart ✅
│   └── livreur_home_page_bloc.dart ✅
└── main.dart

test/
├── features/
│   ├── auth/
│   │   ├── presentation/bloc/auth_bloc_test.dart
│   │   └── domain/usecases/login_usecase_test.dart
│   └── deliveries/
│       ├── presentation/bloc/deliveries_bloc_test.dart
│       └── fixtures/
└── integration_tests.dart
```

---

## 🚀 Installation

### Prérequis
- Flutter >= 3.7.0
- Dart >= 2.17.0

### Étapes

```bash
# 1. Cloner
cd Delivery_Express_Mobility_frontend

# 2. Installer dépendances
flutter pub get
flutter pub run build_runner build

# 3. Lancer
flutter run
```

---

## ⚡ Démarrage rapide

### Utiliser un BLoC
```dart
BlocProvider(
  create: (context) => getIt<DeliveriesBloc>()
    ..add(const FetchDeliveriesEvent()),
  child: BlocBuilder<DeliveriesBloc, DeliveriesState>(
    builder: (context, state) {
      if (state is DeliveriesLoading) return LoadingWidget();
      if (state is DeliveriesLoaded) return DeliveryList(state.deliveries);
      if (state is DeliveriesFailure) return ErrorWidget(state.message);
      return SizedBox.shrink();
    },
  ),
)
```

### WebSocket temps réel
```dart
final socketService = getIt<SocketService>();
await socketService.connect();

socketService.events.listen((event) {
  if (event['type'] == 'delivery_assigned') {
    refreshDeliveries();
  }
});
```

---

## 📚 Documentation

1. [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Vue d'ensemble
2. [QUICK_START.md](docs/QUICK_START.md) - Mise en route
3. [TESTING_GUIDE.md](docs/TESTING_GUIDE.md) - Tests
4. [WEBSOCKET_GUIDE.md](docs/WEBSOCKET_GUIDE.md) - WebSocket
5. [PERFORMANCE_GUIDE.md](docs/PERFORMANCE_GUIDE.md) - Performance
6. [PHASE_2_COMPLETION.md](docs/PHASE_2_COMPLETION.md) - Phase 2 recap

---

## 🧪 Tests

```bash
# Tous les tests
flutter test

# Test spécifique
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart

# Couverture
flutter test --coverage
```

**Coverage actuel:**
- AuthBloc: 100% (9 tests)
- DeliveriesBloc: 100% (8 tests)
- LoginUseCase: 100% (6 tests)
- Total: 23+ tests

---

## ⚡ Performance

### Optimisations
- ✅ Cache local (Hive)
- ✅ Lazy loading images
- ✅ BLoC réutilisé
- ✅ Widget rebuilding optimisé
- ✅ Mode offline

### Benchmarks
| Opération | Target |
|-----------|--------|
| App startup | < 2s |
| Charger livraisons | < 1s |
| Transition page | < 300ms |

---

## 📄 Licence

Proprietary

---

**Status**: Production Ready ✅
