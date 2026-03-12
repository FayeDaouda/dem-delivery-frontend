import 'package:delivery_express_mobility_frontend/features/deliveries/domain/repositories/deliveries_repository.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRidesService {
  final Dio _dio;
  final DeliveriesRepository _deliveriesRepository;

  DriverRidesService({
    required Dio dio,
    required DeliveriesRepository deliveriesRepository,
  })  : _dio = dio,
        _deliveriesRepository = deliveriesRepository;

  /// Charger tout l'historique de livraisons
  Future<List<Map<String, dynamic>>> loadDeliveryHistory() async {
    // 1) Source canonique: module shared deliveries (clean architecture)
    try {
      final deliveries = await _deliveriesRepository.fetchDeliveries();
      if (deliveries.isNotEmpty) {
        return deliveries
            .map(
              (d) => <String, dynamic>{
                'id': d.id,
                'pickupAddress': d.pickupAddress,
                'deliveryAddress': d.deliveryAddress,
                'status': d.status,
                'clientName': d.clientName,
                'clientPhone': d.clientPhone,
                'amount': d.amount,
                'price': d.amount,
                'gain': d.amount,
                'createdAt': d.createdAt.toIso8601String(),
                'completedAt': d.completedAt?.toIso8601String(),
                'distance': d.distance,
                'estimatedTime': d.estimatedTime,
              },
            )
            .toList();
      }
    } catch (_) {
      // ignore et fallback ci-dessous
    }

    // 2) Fallback legacy: endpoint historique existant
    try {
      final response = await _dio.get('/deliveries/history');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  /// Filtrer les livraisons par statut
  List<Map<String, dynamic>> filterByStatus(
    List<Map<String, dynamic>> deliveries,
    String status,
  ) {
    if (status == 'TOUS') return deliveries;
    return deliveries.where((d) {
      final deliveryStatus = d['status']?.toString().toUpperCase() ?? '';
      return deliveryStatus == status;
    }).toList();
  }

  /// Obtenir les livraisons du jour
  List<Map<String, dynamic>> getTodayDeliveries(
    List<Map<String, dynamic>> deliveries,
  ) {
    final now = DateTime.now();
    return deliveries.where((e) {
      final created = DateTime.tryParse(e['createdAt']?.toString() ?? '');
      if (created == null) return false;
      return created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
    }).toList();
  }

  /// Extraire les coordonnées de pickup
  LatLng? extractPickupLocation(Map<String, dynamic> delivery) {
    final loc = delivery['pickupLocation'] ??
        delivery['pickup'] ??
        delivery['pickupCoordinates'];
    if (loc is Map) {
      final lat = _toDouble(loc['latitude'] ?? loc['lat']);
      final lng = _toDouble(loc['longitude'] ?? loc['lng'] ?? loc['lon']);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    final lat = _toDouble(delivery['pickupLat'] ?? delivery['latitude']);
    final lng = _toDouble(delivery['pickupLng'] ?? delivery['longitude']);
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  /// Convertir en double
  double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
