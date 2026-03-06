# Phase 2 - Performance Optimization Guide

## 📋 Overview

This guide covers performance optimizations for the Delivery Express Mobility frontend, including:
- Memory profiling with DevTools
- Widget rebuilding optimization
- Network optimization
- Cache layer implementation
- Offline mode strategy

---

## 1. Memory Profiling avec Flutter DevTools

### Lancer DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Analyser la mémoire
1. Ouvrir **Memory tab** dans DevTools
2. Prendre un snapshot initial
3. Effectuer une action (ex: charger une livraison)
4. Prendre un nouveau snapshot
5. Comparer les deux pour identifier les fuites mémoire

### Exemple de problème identifié
```dart
// ❌ MAUVAIS - Créé un nouveau BLoC à chaque rebuild
@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (_) => DeliveriesBloc(...), // ← Crée une nouvelle instance
    child: MyWidget(),
  );
}

// ✅ BON - Réutilise le BLoC existant
@override
Widget build(BuildContext context) {
  return BlocProvider.value(
    value: _deliveriesBloc, // ← Utilise l'instance existante
    child: MyWidget(),
  );
}
```

---

## 2. Widget Rebuilding Optimization

### Identifier les rebuilds inutiles
```dart
// Dans le widget problématique:
@override
Widget build(BuildContext context) {
  print('🔄 DeliveryCard rebuilding'); // ← Ajouter un log temporaire
  return _buildContent();
}
```

### Optimisation 1: Scinder le BlocBuilder
```dart
// ❌ MAUVAIS - Tout se reconstruit quand l'état change
BlocBuilder<DeliveriesBloc, DeliveriesState>(
  builder: (context, state) {
    return Column(
      children: [
        DeliveryList(deliveries: state.deliveries),
        DeliveryStats(stats: state.stats),
      ],
    );
  },
);

// ✅ BON - Chaque section rebuild indépendamment
Column(
  children: [
    BlocBuilder<DeliveriesBloc, DeliveriesState>(
      buildWhen: (prev, curr) => prev.deliveries != curr.deliveries,
      builder: (context, state) => DeliveryList(deliveries: state.deliveries),
    ),
    BlocBuilder<DeliveriesBloc, DeliveriesState>(
      buildWhen: (prev, curr) => prev.stats != curr.stats,
      builder: (context, state) => DeliveryStats(stats: state.stats),
    ),
  ],
);
```

### Optimisation 2: Utiliser const constructors
```dart
// ✅ MIEUX - Les Widgets const ne se recréent pas
class _DeliveryCard extends StatelessWidget {
  final Delivery delivery;

  const _DeliveryCard({required this.delivery}); // ← const constructor

  @override
  Widget build(BuildContext context) {
    return const Card( // ← const Widget
      child: ListTile(...),
    );
  }
}
```

---

## 3. Network Optimization

### Batch API Requests
```dart
// ❌ MAUVAIS - 10 appels réseau séquentiels
Future<void> loadDeliveries(List<String> ids) async {
  for (var id in ids) {
    await api.fetchDelivery(id); // ← 10 requêtes!
  }
}

// ✅ BON - 1 appel réseau pour tout
Future<void> loadDeliveries(List<String> ids) async {
  await api.fetchDeliveries(ids); // ← 1 requête
}
```

### Compression des données
```dart
// Dans DeliveriesRemoteDataSource, ajouter:
final response = await dio.get(
  '/api/deliveries',
  options: Options(
    headers: {
      'Accept-Encoding': 'gzip', // ← Demander la compression
    },
  ),
);
```

### Timeout management
```dart
final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 5), // ← Timeout de connexion
    receiveTimeout: const Duration(seconds: 10), // ← Timeout de réception
  ),
);
```

---

## 4. Cache Layer avec Hive

### Implémentation complète
```dart
// ✅ Déjà créée dans deliveries_local_data_source.dart
// Mais ajouter sérialisation JSON complète:

class DeliveriesLocalDataSourceImpl implements DeliveriesLocalDataSource {
  @override
  Future<void> cacheDeliveries(List<Delivery> deliveries) async {
    final box = await Hive.openBox<String>('deliveries');
    
    // Sérialiser en JSON
    final jsonList = deliveries
        .map((d) => jsonEncode(d.toJson()))
        .toList();
    
    await box.put('deliveries_cache', jsonEncode(jsonList));
  }

  @override
  Future<List<Delivery>> getCachedDeliveries() async {
    final box = await Hive.openBox<String>('deliveries');
    final cached = box.get('deliveries_cache');
    
    if (cached == null) return [];
    
    // Désérialiser depuis JSON
    final jsonList = jsonDecode(cached) as List;
    return jsonList
        .map((json) => Delivery.fromJson(json))
        .toList();
  }
}
```

### Cache expiration
```dart
// Ajouter timestamp au cache
class CachedData {
  final List<Delivery> deliveries;
  final DateTime timestamp;
  
  bool get isExpired => 
    DateTime.now().difference(timestamp).inMinutes > 30;
}
```

---

## 5. Offline Mode Strategy

### Détection du mode offline
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  
  Stream<bool> get isOnline =>
    _connectivity.onConnectivityChanged
        .map((result) => result != ConnectivityResult.none);
}
```

### Queueing offline updates
```dart
class OfflineUpdateQueue {
  final List<PendingUpdate> _queue = [];
  final LocalDataSource _localDataSource;
  
  Future<void> addPendingUpdate(String deliveryId, String status) async {
    _queue.add(PendingUpdate(deliveryId: deliveryId, status: status));
    await _localDataSource.savePendingUpdates(_queue);
  }
  
  Future<void> syncPendingUpdates() async {
    for (var update in _queue) {
      try {
        await repository.updateDeliveryStatus(
          update.deliveryId,
          update.status,
        );
        _queue.remove(update);
      } catch (e) {
        // Relancer à la prochaine connexion
        return;
      }
    }
  }
}
```

---

## 6. Image Optimization

### Lazy loading images
```dart
// ❌ MAUVAIS - Charge toutes les images immédiatement
ListView.builder(
  itemBuilder: (ctx, i) => Image.network(deliveries[i].imageUrl),
);

// ✅ BON - Charge seulement les images visibles
ListView.builder(
  itemBuilder: (ctx, i) => Image.network(
    deliveries[i].imageUrl,
    cacheHeight: 300, // ← Redimensionner en cache
    cacheWidth: 300,
  ),
);
```

### Utiliser cached_network_image
```dart
// Ajouter à pubspec.yaml:
// cached_network_image: ^3.3.0

CachedNetworkImage(
  imageUrl: delivery.photoUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  cacheManager: CustomCacheManager.instance,
)
```

---

## 7. Performance Monitoring

### Instrumenter le code
```dart
Future<void> fetchDeliveries() async {
  final stopwatch = Stopwatch()..start();
  
  try {
    final deliveries = await repository.fetchDeliveries();
    stopwatch.stop();
    
    // Log timing
    debugPrint('✅ Fetched ${deliveries.length} deliveries '
        'in ${stopwatch.elapsedMilliseconds}ms');
  } catch (e) {
    stopwatch.stop();
    debugPrint('❌ Failed to fetch deliveries '
        'in ${stopwatch.elapsedMilliseconds}ms: $e');
  }
}
```

### Utiliser Firebase Performance Monitoring (optionnel)
```dart
import 'package:firebase_performance/firebase_performance.dart';

final trace = FirebasePerformance.instance.newTrace('deliveries_fetch');
await trace.start();

try {
  final deliveries = await fetchDeliveries();
  trace.putAttribute('delivery_count', deliveries.length.toString());
} finally {
  await trace.stop();
}
```

---

## 8. Testing Performance

### Benchmark tests
```dart
void main() {
  group('Performance Tests', () {
    test('Fetching 100 deliveries should complete in < 2 seconds', () async {
      final stopwatch = Stopwatch()..start();
      
      // Simuler 100 livraisons
      final deliveries = List.generate(
        100,
        (i) => Delivery(id: '$i', ...),
      );
      
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
```

---

## 9. Checklist Performance Optimization

- [ ] Profile memory usage avec DevTools
- [ ] Identifier et corriger les widget rebuilds inutiles
- [ ] Implémenter `buildWhen` dans les BlocBuilders
- [ ] Utiliser `const` constructors partout
- [ ] Optimiser les requêtes réseau (batch, compression)
- [ ] Tester la cache Hive en mode offline
- [ ] Implémenter la détection de connectivité
- [ ] Configurer les timeouts réseau
- [ ] Ajouter lazy loading pour les images
- [ ] Mesurer les performances critiques
- [ ] Documenter les bottlenecks identifiés

---

## 10. Benchmarks de Reference

| Opération | Target | Acceptable |
|-----------|--------|-----------|
| Démarrage app | < 2s | < 3s |
| Chargement liste livraisons | < 1s | < 2s |
| Transition page | < 300ms | < 500ms |
| Mise à jour statut | < 500ms | < 1s |
| Cache lookup | < 50ms | < 100ms |

---

## Ressources

- [Flutter Performance Best Practices](https://flutter.dev/docs/testing/best-practices)
- [DevTools Memory Profiling](https://flutter.dev/docs/development/tools/devtools/memory)
- [Hive Documentation](https://docs.hivedb.dev)
- [Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon)
