# 🚀 Guide Rapide - Démarrage avec la nouvelle architecture

## 1️⃣ Installation

```bash
# Récupérer les dépendances
flutter pub get

# Optionnel: Générer les mocks pour tests
flutter pub run build_runner build
```

## 2️⃣ Comprendre le pattern

### Avant (ancien code):
```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  Future<void> _loadData() async {
    setState(() => loading = true);
    final data = await api.fetch();
    setState(() { this.data = data; loading = false; });
  }
}
```

### Après (BLoC):
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(context) {
    return BlocProvider(
      create: (_) => getIt<MyBloc>()..add(MyInitEvent()),
      child: BlocBuilder<MyBloc, MyState>(
        builder: (context, state) {
          if (state is Loading) return Spinner();
          if (state is Loaded) return Content(state.data);
          return Error();
        },
      ),
    );
  }
}
```

**Différences clés:**
- ✅ Pas de `setState()`
- ✅ Pas de `initState/dispose`
- ✅ UI purement déclarative
- ✅ Logique testable indépendamment

---

## 3️⃣ Architecture en couches

### Domain Layer (Cœur métier)
```
Responsabilité: Logique métier pure
Dépend de: Rien
Contient: Entities, Repositories abstraits, Use Cases
```

Exemple:
```dart
// Entity
class Delivery {
  final String id, address;
  final String status; // Logique pure
}

// Use Case
class FetchDeliveriesUseCase {
  final DeliveriesRepository repository;
  Future<List<Delivery>> call() => repository.fetchDeliveries();
}
```

### Data Layer (Implémentation)
```
Responsabilité: Récupérer les données
Dépend de: Domain layer
Contient: RemoteDataSources, Models, Repository impls
```

Exemple:
```dart
// Remote Data Source (API)
class DeliveriesRemoteDataSourceImpl {
  Future<List<DeliveryModel>> fetchDeliveries() async {
    final response = await dio.get('/deliveries');
    return response.data['data'].map(DeliveryModel.fromJson).toList();
  }
}

// Repository Implementation
class DeliveriesRepositoryImpl implements DeliveriesRepository {
  @override
  Future<List<Delivery>> fetchDeliveries() 
    => remoteDataSource.fetchDeliveries();
}
```

### Presentation Layer (UI)
```
Responsabilité: Affichage et interaction
Dépend de: Domain layer (via BLoC)
Contient: BLoCs, Pages, Widgets
```

Exemple:
```dart
// Events
class FetchDeliveriesEvent {}

// States
class DeliveriesLoaded {
  final List<Delivery> deliveries;
}

// BLoC
class DeliveriesBloc extends Bloc<Event, State> {
  DeliveriesBloc(this.useCase) {
    on<FetchDeliveriesEvent>((event, emit) async {
      emit(Loading());
      try {
        final data = await useCase();
        emit(DeliveriesLoaded(data));
      } catch (e) {
        emit(Failure(e.message));
      }
    });
  }
}

// Page
class ClientPage extends StatelessWidget {
  @override
  Widget build(context) => BlocBuilder<DeliveriesBloc, State>(
    builder: (context, state) { ... }
  );
}
```

---

## 4️⃣ Injection de dépendances (GetIt)

**Configuration** (`lib/core/di/service_locator.dart`):
```dart
final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Déclarer une fois
  getIt.registerSingleton<MyBloc>(
    MyBloc(
      useCase: getIt<MyUseCase>(),
    ),
  );
}
```

**Utilisation:**
```dart
// Dans BLoC
context.read<MyBloc>().add(MyEvent());

// Ailleurs
final bloc = getIt<MyBloc>();
bloc.add(MyEvent());
```

**Avantages:**
✅ Pas de constructeur complexe
✅ Testable (swap implémentations)
✅ Centralisé

---

## 5️⃣ WebSocket - Temps réel

```dart
// Connecter après login
final socket = getIt<SocketService>();
await socket.connect(
  'wss://backend.com/socket',
  accessToken,
);

// Écouter les événements
socket.events.listen((event) {
  print('Événement: ${event.type}');
  
  if (event.type == WebSocketEventType.deliveryAssigned) {
    // Déclencher action (ex: refresh BLoC)
    context.read<DeliveriesBloc>()
        .add(FetchDeliveriesEvent());
  }
});

// Déconnecter
await socket.disconnect();
```

**Événements supportés:**
- `driver_online` - Chauffeur connecté
- `delivery_assigned` - Livraison assignée
- `delivery_status_changed` - Statut changé
- `pass_activated` - Pass activé

---

## 6️⃣ Exemple complet: Page de Livraisons

**Structure:**
```
features/deliveries/
├── domain/
│   ├── entities/delivery.dart
│   ├── repositories/deliveries_repository.dart
│   └── usecases/deliveries_usecases.dart
├── data/
│   ├── datasources/deliveries_remote_data_source.dart
│   ├── models/delivery_model.dart
│   └── repositories/deliveries_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── deliveries_bloc.dart
    │   ├── deliveries_event.dart
    │   └── deliveries_state.dart
    └── pages/deliveries_page.dart
```

**Implémentation:**

1. **Entity** (domain/entities/delivery.dart):
```dart
class Delivery {
  final String id, address;
  final String status;
}
```

2. **Use Case** (domain/usecases/deliveries_usecases.dart):
```dart
class FetchDeliveriesUseCase {
  final DeliveriesRepository repository;
  Future<List<Delivery>> call() => repository.fetchDeliveries();
}
```

3. **Model** (data/models/delivery_model.dart):
```dart
class DeliveryModel extends Delivery {
  factory DeliveryModel.fromJson(json) => DeliveryModel(...);
}
```

4. **Data Source** (data/datasources/deliveries_remote_data_source.dart):
```dart
class DeliveriesRemoteDataSourceImpl {
  Future<List<DeliveryModel>> fetchDeliveries() async {
    final response = await dio.get('/deliveries');
    return response.data['data']
        .map((d) => DeliveryModel.fromJson(d))
        .toList();
  }
}
```

5. **Repository Impl** (data/repositories/deliveries_repository_impl.dart):
```dart
class DeliveriesRepositoryImpl implements DeliveriesRepository {
  @override
  Future<List<Delivery>> fetchDeliveries() =>
      remoteDataSource.fetchDeliveries();
}
```

6. **BLoC** (presentation/bloc/deliveries_bloc.dart):
```dart
class DeliveriesBloc extends Bloc<DeliveriesEvent, DeliveriesState> {
  final FetchDeliveriesUseCase useCase;
  
  DeliveriesBloc({required this.useCase}) : super(Initial()) {
    on<FetchDeliveriesEvent>((event, emit) async {
      emit(Loading());
      try {
        final deliveries = await useCase();
        emit(Loaded(deliveries));
      } catch (e) {
        emit(Failure(e.toString()));
      }
    });
  }
}
```

7. **Page** (presentation/pages/deliveries_page.dart):
```dart
class DeliveriesPage extends StatelessWidget {
  @override
  Widget build(context) {
    return BlocProvider(
      create: (_) => getIt<DeliveriesBloc>()
          ..add(const FetchDeliveriesEvent()),
      child: BlocBuilder<DeliveriesBloc, DeliveriesState>(
        builder: (context, state) {
          if (state is Loading) return Spinner();
          if (state is Loaded) {
            return ListView(
              children: state.deliveries
                  .map((d) => DeliveryCard(d))
                  .toList(),
            );
          }
          if (state is Failure) return Error(state.message);
          return SizedBox.shrink();
        },
      ),
    );
  }
}
```

---

## 7️⃣ Tests

**Test d'un BLoC:**
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('DeliveriesBloc', () {
    late MockFetchDeliveriesUseCase mockUseCase;
    late DeliveriesBloc bloc;

    setUp(() {
      mockUseCase = MockFetchDeliveriesUseCase();
      bloc = DeliveriesBloc(useCase: mockUseCase);
    });

    blocTest<DeliveriesBloc, DeliveriesState>(
      'emits [Loading, Loaded] when fetch succeeds',
      build: () {
        when(mockUseCase()).thenAnswer((_) async => [
          const Delivery(id: '1', address: 'Dakar'),
        ]);
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchDeliveriesEvent()),
      expect: () => [
        const Loading(),
        isA<Loaded>(),
      ],
    );
  });
}
```

**Tester le Use Case:**
```dart
test('FetchDeliveriesUseCase calls repository', () async {
  final mockRepository = MockDeliveriesRepository();
  final useCase = FetchDeliveriesUseCase(repository: mockRepository);

  when(mockRepository.fetchDeliveries())
      .thenAnswer((_) async => []);

  await useCase();

  verify(mockRepository.fetchDeliveries()).called(1);
});
```

---

## 8️⃣ Checklist de Déploiement

Avant de pusher du code:

```bash
# 1. Analyser
flutter analyze

# 2. Formatter
dart format lib/

# 3. Tester
flutter test

# 4. Builder
flutter pub get

# 5. Compiler (test)
flutter build apk --split-per-abi  # Android
flutter build ios                   # iOS
```

---

## 9️⃣ Ressources rapides

```
📚 Documentation:
  - ARCHITECTURE.md     → Explication complète
  - MIGRATION_GUIDE.md  → Guide migration pages
  - Ce fichier          → Quick start

🔗 Liens externes:
  - https://bloclibrary.dev/
  - https://pub.dev/packages/get_it
  - https://pub.dev/packages/equatable

📁 Fichiers clés:
  - lib/core/di/service_locator.dart      → DI
  - lib/core/services/socket_service.dart → WebSocket
  - lib/main.dart                         → Entry point
```

---

## 🆘 Besoin d'aide ?

**Q: Comment ajouter une nouvelle page?**
A: Copier le pattern de `ClientHomePage`:
```dart
BlocProvider(
  create: (_) => getIt<MyBloc>(),
  child: BlocBuilder<MyBloc, MyState>(...)
)
```

**Q: Erreur "BLoC not found in context"?**
A: Vérifier que `BlocProvider` enveloppe le `BlocBuilder`

**Q: Comment tester?**
A: Voir `test/bloc_test_example.dart`

**Q: Besoin de WebSocket?**
A: Utiliser `getIt<SocketService>()` après login

---

**Dernière mise à jour:** 4 Mars 2026
**Version:** 1.0 - Architecture BLoC/Clean
