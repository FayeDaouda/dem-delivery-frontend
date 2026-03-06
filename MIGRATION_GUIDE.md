# Guide de Migration - Pages existantes vers BLoC

## 📋 Résumé

Ce guide explique comment migrer les pages existantes (ClientHomePage, LivreurHomePage) de `setState` vers le **BLoC Pattern**.

---

## ✅ Checklist par page

### 1. **ClientHomePage** (Afficher les livraisons)

**Avant (setState):**
```dart
class ClientHomePage extends StatefulWidget {
  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  List<Delivery> deliveries = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() => loading = true);
    final data = await apiClient.fetchDeliveries();
    setState(() {
      deliveries = data;
      loading = false;
    });
  }

  @override
  Widget build(context) {
    if (loading) return CircularProgressIndicator();
    return ListView(
      children: deliveries.map((d) => DeliveryCard(d)).toList(),
    );
  }
}
```

**Après (BLoC):**
```dart
class ClientHomePage extends StatelessWidget {
  @override
  Widget build(context) {
    return BlocProvider(
      create: (_) => getIt<DeliveriesBloc>()
        ..add(const FetchDeliveriesEvent()),
      child: BlocBuilder<DeliveriesBloc, DeliveriesState>(
        builder: (context, state) {
          if (state is DeliveriesLoading) {
            return CircularProgressIndicator();
          }
          if (state is DeliveriesLoaded) {
            return ListView(
              children: state.deliveries
                  .map((d) => DeliveryCard(d))
                  .toList(),
            );
          }
          if (state is DeliveriesFailure) {
            return ErrorWidget(state.message);
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}
```

**Étapes:**
1. [ ] Remplacer `StatefulWidget` → `StatelessWidget`
2. [ ] Supprimer `initState`, `setState`
3. [ ] Envelopper avec `BlocProvider(create: ... getIt<DeliveriesBloc>())`
4. [ ] Utiliser `BlocBuilder` pour tous les états
5. [ ] Tester chaque state (Loading, Loaded, Failure)

---

### 2. **LivreurHomePage** (Dashboard chauffeur)

**Avant:**
```dart
class LivreurHomePage extends StatefulWidget {
  @override
  State<LivreurHomePage> createState() => _LivreurHomePageState();
}

class _LivreurHomePageState extends State<LivreurHomePage> {
  List<Delivery> assignedDeliveries = [];
  
  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _connectWebSocket(); // Manuel
  }

  void _connectWebSocket() {
    socket.on('delivery_assigned', (data) {
      setState(() => assignedDeliveries.add(data));
    });
  }
}
```

**Après (avec WebSocket + BLoC):**
```dart
class LivreurHomePage extends StatelessWidget {
  @override
  Widget build(context) {
    return BlocProvider(
      create: (_) => getIt<DeliveriesBloc>()
        ..add(const FetchDeliveriesEvent()),
      child: _LivreurContent(),
    );
  }
}

class _LivreurContent extends StatefulWidget {
  @override
  State<_LivreurContent> createState() => _LivreurContentState();
}

class _LivreurContentState extends State<_LivreurContent> {
  late StreamSubscription _socketSubscription;

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    final socket = getIt<SocketService>();
    _socketSubscription = socket.events.listen((event) {
      if (event.type == WebSocketEventType.deliveryAssigned) {
        // Rafraîchir les livraisons
        context.read<DeliveriesBloc>()
            .add(const FetchDeliveriesEvent());
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(context) {
    return BlocBuilder<DeliveriesBloc, DeliveriesState>(
      builder: (context, state) {
        if (state is DeliveriesLoading) {
          return LoadingWidget();
        }
        if (state is DeliveriesLoaded) {
          return DeliveriesList(state.deliveries);
        }
        return ErrorWidget();
      },
    );
  }
}
```

**Étapes:**
1. [ ] Créer feature `deliveries` (déjà fait ✅)
2. [ ] Envelopper avec `BlocProvider<DeliveriesBloc>`
3. [ ] Écouter WebSocket dans `State` pour rafraîchissement
4. [ ] Remplacer manuel WebSocket par `getIt<SocketService>()`
5. [ ] Tester synchronisation temps réel

---

### 3. **Passes Page** (Activation de passes)

**Avant:**
```dart
class PassesPage extends StatefulWidget {
  @override
  State<PassesPage> createState() => _PassesPageState();
}

class _PassesPageState extends State<PassesPage> {
  List<Pass> availablePasses = [];
  List<Pass> userPasses = [];

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  Future<void> _activatePass(String passId) async {
    setState(() => isLoading = true);
    try {
      await apiClient.activatePass(passId);
      await _loadPasses();
    } catch (e) {
      _showError(e.toString());
    }
  }
}
```

**Après (Cubit):**
```dart
class PassesPage extends StatelessWidget {
  @override
  Widget build(context) {
    return BlocProvider(
      create: (_) => getIt<PassesCubit>()..fetchAvailablePasses(),
      child: _PassesContent(),
    );
  }
}

class _PassesContent extends StatelessWidget {
  @override
  Widget build(context) {
    return Column(
      children: [
        BlocBuilder<PassesCubit, PassesState>(
          builder: (context, state) {
            if (state is PassesLoading) return LoadingWidget();
            if (state is AvailablePassesLoaded) {
              return PassGrid(
                passes: state.passes,
                onActivate: (passId) {
                  context.read<PassesCubit>().activatePass(passId);
                },
              );
            }
            return ErrorWidget();
          },
        ),
      ],
    );
  }
}
```

**Étapes:**
1. [ ] Utiliser `PassesCubit` (déjà implémenté ✅)
2. [ ] Convertir en `StatelessWidget`
3. [ ] Envelopper avec `BlocProvider<PassesCubit>`
4. [ ] BlocBuilder pour `availablePasses`
5. [ ] BlocListener pour afficher toast d'activation
6. [ ] Tester activation de pass

---

## 🔄 Pattern de migration générique

Pour **toute** page:

**AVANT:**
```dart
class MyPage extends StatefulWidget {
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  MyData data;
  bool loading = false;
  String? error;

  void initState() {
    _loadData();
  }

  Future<void> _loadData() {
    setState(() => loading = true);
    // ...
    setState(() { data = ...; loading = false; });
  }

  void build(context) {
    if (loading) return Spinner();
    return ListView(...);
  }
}
```

**APRÈS:**
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(context) {
    return BlocProvider(
      create: (_) => getIt<MyBloc>()..add(MyInitialEvent()),
      child: BlocBuilder<MyBloc, MyState>(
        builder: (context, state) {
          if (state is MyLoading) return Spinner();
          if (state is MyLoaded) return Content(state.data);
          if (state is MyError) return ErrorWidget(state.message);
          return SizedBox.shrink();
        },
      ),
    );
  }
}
```

---

## 🧪 Checklist de test

Pour chaque page migrée:

- [ ] Loading state s'affiche
- [ ] Success state affiche les données
- [ ] Error state affiche message d'erreur
- [ ] Bouton d'action déclenche BLoC event
- [ ] WebSocket updates rafraîchit BLoC
- [ ] Aucune fuite mémoire (dispose correctement)
- [ ] Navigation après action fonctionne

---

## 🚀 Ordre de migration recommandé

1. **LoginPage** ✅ (Déjà fait)
2. **ClientHomePage** (Simple, affichage liste)
3. **PassesPage** (Médium, avec actions)
4. **LivreurHomePage** (Complexe, avec WebSocket)
5. Autres pages...

---

## 📝 Notes importantes

### Refetch après action
```dart
// Après activation d'une action
if (state is MyActionSuccess) {
  context.read<MyBloc>().add(MyRefreshEvent());
}
```

### BlocListener pour side effects
```dart
BlocListener<MyBloc, MyState>(
  listener: (context, state) {
    if (state is MySuccess) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Succès')));
    }
  },
  child: BlocBuilder<MyBloc, MyState>(
    builder: (context, state) { ... }
  ),
)
```

### Débounce pour recherche
```dart
on<SearchEvent>((event, emit) {
  // Ajouter délai avant appel API
}, transformer: debounceTime(Duration(milliseconds: 500)));
```

---

**Consignes finales:**
✅ Compiler `flutter pub get` après chaque changement
✅ Tester chaque page migrée
✅ Commiter par feature
✅ Supprimer ancien code après confirmation
