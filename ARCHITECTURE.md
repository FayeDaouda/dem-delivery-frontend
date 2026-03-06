# Architecture Frontend Flutter - Delivery Express Mobility

## 🏗️ Vue d'ensemble

Le frontend est structuré suivant une **Clean Architecture** avec **BLoC Pattern** pour une meilleure séparation des responsabilités, testabilité et évolutivité.

```
lib/
├── core/                           # Services & configuration partagés
│   ├── di/
│   │   └── service_locator.dart   # GetIt - Injection de dépendances
│   ├── network/
│   │   └── api_client.dart        # Ancien (à remplacer progressivement)
│   ├── services/
│   │   └── socket_service.dart    # WebSocket pour temps réel
│   └── storage/
│       └── secure_storage_service.dart
│
├── features/                        # Features métier
│   ├── auth/
│   │   ├── domain/                # Couche métier (Indépendante de l'implémentation)
│   │   │   ├── entities/          # Modèles de domaine (AuthUser)
│   │   │   ├── repositories/      # Interface des repositories
│   │   │   └── usecases/          # Cas d'usage (LoginUseCase, etc.)
│   │   │
│   │   ├── data/                  # Couche données
│   │   │   ├── datasources/       # Implémentation API (RemoteDataSource)
│   │   │   ├── models/            # Conversion JSON (AuthUserModel)
│   │   │   └── repositories/      # Implémentation repository
│   │   │
│   │   └── presentation/          # Couche UI
│   │       └── bloc/              # BLoC (AuthBloc)
│   │           ├── auth_bloc.dart
│   │           ├── auth_event.dart
│   │           └── auth_state.dart
│   │
│   ├── deliveries/                # Feature Livraisons
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/bloc/     # DeliveriesBloc
│   │
│   └── passes/                    # Feature Passes/Commissions
│       ├── domain/
│       ├── data/
│       └── presentation/cubit/    # PassesCubit
│
├── pages/                          # Pages (UI - Stateless + BLoC)
│   ├── login_page_bloc.dart       # Nouvelle implémentation avec BLoC
│   ├── login_page.dart            # Ancienne (à supprimer après migration)
│   └── ...
│
└── widgets/                        # Widgets réutilisables
```

---

## 🔄 Flux de données (Unidirectionnel)

```
UI (StatelessWidget + BlocBuilder)
    ↓
BLoC / Cubit (Event → State)
    ↓
Use Cases (Logique métier)
    ↓
Repository (Abstraction)
    ↓
Data Source / API (Implémentation)
    ↓
Backend
```

---

## 📦 Couches de l'Architecture

### 1. **Domain Layer** (Domaine métier)
- **Indépendant** de Flutter, Dio, SharedPreferences
- Contient la logique métier pure
- Définis les interfaces (`abstract class`)

**Exemple :**
```dart
// Entity
class AuthUser {
  final String phone;
  final String role;
  // ...
}

// Repository Interface
abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String phone, String password);
}

// Use Case
class LoginUseCase {
  final AuthRepository repository;
  Future<Map<String, dynamic>> call(String phone, String password) 
    => repository.login(phone, password);
}
```

### 2. **Data Layer** (Implémentation)
- Récupère les données (API, BD locale)
- Convertit JSON ↔ Models
- Implémente les interfaces du domain

**Exemple :**
```dart
// Remote Data Source (API)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  Future<Map<String, dynamic>> login(...) => dio.post('/auth/login', ...);
}

// Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  @override
  Future<Map<String, dynamic>> login(...) => remoteDataSource.login(...);
}

// Model (Conversion JSON)
class AuthUserModel extends AuthUser {
  factory AuthUserModel.fromJson(Map json) => AuthUserModel(...);
  Map<String, dynamic> toJson() => {...};
}
```

### 3. **Presentation Layer** (UI)
- BLoC / Cubit gère les states
- Widgets Stateless + BlocBuilder / BlocListener
- Événements → Logic → États

**Exemple :**
```dart
// Events
abstract class AuthEvent {}
class AuthLoginEvent extends AuthEvent {
  final String phone, password;
}

// States
abstract class AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final String role;
}
class AuthFailure extends AuthState {
  final String message;
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(...) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLoginEvent);
  }
  
  Future<void> _onLoginEvent(AuthLoginEvent e, Emitter emit) async {
    emit(AuthLoading());
    try {
      final response = await loginUseCase(e.phone, e.password);
      emit(AuthSuccess(...));
    } catch (e) {
      emit(AuthFailure(...));
    }
  }
}

// Widget
class LoginPage extends StatelessWidget {
  @override
  Widget build(context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) return CircularProgressIndicator();
        if (state is AuthSuccess) return HomePage();
        if (state is AuthFailure) return ErrorMessage(state.message);
      },
    );
  }
}
```

---

## 🔌 Service Locator (GetIt) - Injection de dépendances

**Fichier:** `lib/core/di/service_locator.dart`

```dart
final getIt = GetIt.instance;

await setupDependencies();

// Récupérer dans BLoC/Page
context.read<AuthBloc>()
getIt<AuthBloc>()
```

**Avantages:**
✅ Pas de constructeurs compliqués
✅ Facile à tester (mock les dépendances)
✅ Réutilisable dans tout l'app

---

## 🔌 WebSocket - Temps réel

**Fichier:** `lib/core/services/socket_service.dart`

```dart
// Connecter dans main() ou après login
final socket = getIt<SocketService>();
await socket.connect(wsUrl, accessToken);

// Écouter les événements
socket.events.listen((event) {
  if (event.type == WebSocketEventType.deliveryAssigned) {
    // Traiter livraison assignée
    context.read<DeliveriesBloc>().add(FetchDeliveriesEvent());
  }
});
```

**Événements supportés:**
- `driver_online` → Chauffeur connecté
- `delivery_assigned` → Livraison assignée
- `delivery_status_changed` → Statut changé
- `pass_activated` → Pass activé

---

## ✅ Avantages de cette Architecture

| Aspect | Avantage |
|--------|----------|
| **Testabilité** | Domain layer ne dépend de rien → tests purs |
| **Maintenabilité** | Changement API = modif de la data layer uniquement |
| **Réutilisabilité** | UseCases indépendants, réutilisables |
| **Scalabilité** | Ajouter features = copier le pattern |
| **Séparation** | UI ne connaît pas API, API ne connaît pas UI |
| **WebSocket** | Service injecté, décorrélé de la logique métier |

---

## 🚀 Checklist de migration

- [x] Créer structure domain/data/presentation
- [x] Implémenter AuthBloc + AuthRepository
- [x] Implémenter DeliveriesBloc + DeliveriesRepository
- [x] Implémenter PassesCubit + PassesRepository
- [x] Créer SocketService pour WebSocket
- [x] Configurer GetIt (Service Locator)
- [x] Créer LoginPage avec BLoC
- [ ] Migrer ClientHomePage
- [ ] Migrer LivreurHomePage
- [ ] Tester et déboguer
- [ ] Supprimer anciennes pages

---

## 🔗 Ajouter une nouvelle feature

1. **Créer la structure:**
```bash
features/feature_name/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/
    └── bloc/ (ou cubit/)
```

2. **Implémenter:**
   - Entity → Repository interface → Use Cases
   - RemoteDataSource → Model → Repository impl
   - BLoC/Cubit → States/Events
   - Enregistrer dans GetIt

3. **Utiliser dans UI:**
```dart
BlocBuilder<MyBloc, MyState>(
  builder: (context, state) { ... }
)
```

---

## 📚 Ressources

- [BLoC Library](https://bloclibrary.dev/)
- [Clean Architecture](https://resocoder.com/flutter-clean-architecture)
- [GetIt (Service Locator)](https://pub.dev/packages/get_it)
- [Equatable](https://pub.dev/packages/equatable)

---

**Dernière mise à jour:** 4 Mars 2026
**Auteur:** Architecture Review - Claude Haiku 4.5
