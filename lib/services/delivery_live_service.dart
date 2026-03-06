import 'dart:async';

import 'package:dio/dio.dart';

/// Modèle pour une livraison disponible
class AvailableDelivery {
  final String id;
  final double distance; // en km
  final int price; // en FCFA
  final String pickupAddress;
  final String dropoffAddress;

  AvailableDelivery({
    required this.id,
    required this.distance,
    required this.price,
    required this.pickupAddress,
    required this.dropoffAddress,
  });
}

/// Service pour gérer les livraisons en temps réel
/// Support WebSocket, polling et simulation
class DeliveryLiveService {
  final StreamController<List<AvailableDelivery>> _deliveryController =
      StreamController.broadcast();

  StreamSubscription<List<AvailableDelivery>>? _subscription;
  Timer? _pollingTimer;
  final Dio? _dio;
  final String? _backendUrl;
  final bool _useRealBackend;

  DeliveryLiveService({
    Dio? dio,
    String? backendUrl,
    bool useRealBackend = false,
  })  : _dio = dio,
        _backendUrl = backendUrl,
        _useRealBackend = useRealBackend;

  Stream<List<AvailableDelivery>> get deliveryStream =>
      _deliveryController.stream;

  /// Démarrer l'écoute des livraisons
  void startListening() {
    stopListening();

    if (_useRealBackend && _dio != null && _backendUrl != null) {
      _startPollingBackend();
    } else {
      _simulateLiveDeliveries();
    }
  }

  /// Arrêter l'écoute
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Polling du backend toutes les 10 secondes
  void _startPollingBackend() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final response = await _dio!.get('$_backendUrl/deliveries/nearby');
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['deliveries'] ?? [];
          final deliveries = data
              .map((json) => AvailableDelivery(
                    id: json['id'],
                    distance: (json['distance'] as num).toDouble(),
                    price: json['price'] as int,
                    pickupAddress: json['pickupAddress'],
                    dropoffAddress: json['dropoffAddress'],
                  ))
              .toList();
          _deliveryController.add(deliveries);
        }
      } catch (e) {
        // En cas d'erreur, continuer silencieusement
        // Ou basculer vers simulation
      }
    });
  }

  /// Simulation des livraisons (sera remplacé par WebSocket)
  void _simulateLiveDeliveries() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      final deliveries = _generateRandomDeliveries();
      _deliveryController.add(deliveries);
    });
  }

  /// Générer des livraisons fictives
  List<AvailableDelivery> _generateRandomDeliveries() {
    final random = DateTime.now().millisecond;
    final count = (random % 6) + 1;

    return List.generate(
      count,
      (index) => AvailableDelivery(
        id: 'delivery_${DateTime.now().millisecondsSinceEpoch}_$index',
        distance: 1.2 + (index * 0.7),
        price: 3000 + (index * 500),
        pickupAddress: 'Départ ${index + 1}',
        dropoffAddress: 'Destination ${index + 1}',
      ),
    );
  }

  /// Nettoyer le service
  void dispose() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
    _deliveryController.close();
  }
}
