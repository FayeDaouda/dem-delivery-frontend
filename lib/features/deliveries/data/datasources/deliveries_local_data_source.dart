import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/delivery.dart';

/// LocalDataSource: Gère la mise en cache locale avec Hive
abstract class DeliveriesLocalDataSource {
  Future<List<Delivery>> getCachedDeliveries();
  Future<void> cacheDeliveries(List<Delivery> deliveries);
  Future<void> clearCache();
  Future<Delivery?> getCachedDeliveryById(String id);
  Future<void> updateCachedDeliveryStatus(String id, String newStatus);
}

class DeliveriesLocalDataSourceImpl implements DeliveriesLocalDataSource {
  static const String _deliveriesCacheKey = 'deliveries_cache';
  static const String _cacheTimestampKey = 'deliveries_cache_ts';
  static const String _cacheBoxName = 'deliveries';
  static const Duration _cacheTtl = Duration(hours: 12);

  Future<Box<String>> _openBox() async => Hive.openBox<String>(_cacheBoxName);

  bool _isCacheExpired(String? timestampIso) {
    if (timestampIso == null) return true;
    final ts = DateTime.tryParse(timestampIso);
    if (ts == null) return true;
    return DateTime.now().difference(ts) > _cacheTtl;
  }

  @override
  Future<List<Delivery>> getCachedDeliveries() async {
    try {
      final box = await _openBox();
      final cachedJson = box.get(_deliveriesCacheKey);
      final cacheTs = box.get(_cacheTimestampKey);

      if (cachedJson == null || _isCacheExpired(cacheTs)) {
        return [];
      }

      final decoded = jsonDecode(cachedJson);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((raw) => Delivery.fromJson(Map<String, dynamic>.from(raw)))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la lecture du cache: $e');
    }
  }

  @override
  Future<void> cacheDeliveries(List<Delivery> deliveries) async {
    try {
      final box = await _openBox();
      final deliveriesJson = deliveries.map((d) => d.toJson()).toList();

      await box.put(_deliveriesCacheKey, jsonEncode(deliveriesJson));
      await box.put(_cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Erreur lors de la mise en cache: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _openBox();
      await box.delete(_deliveriesCacheKey);
      await box.delete(_cacheTimestampKey);
    } catch (e) {
      throw Exception('Erreur lors du nettoyage du cache: $e');
    }
  }

  @override
  Future<Delivery?> getCachedDeliveryById(String id) async {
    try {
      final deliveries = await getCachedDeliveries();
      for (final delivery in deliveries) {
        if (delivery.id == id) return delivery;
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la lecture du cache: $e');
    }
  }

  @override
  Future<void> updateCachedDeliveryStatus(String id, String newStatus) async {
    try {
      final deliveries = await getCachedDeliveries();
      if (deliveries.isEmpty) return;

      final updated = deliveries
          .map(
            (d) => d.id == id
                ? Delivery(
                    id: d.id,
                    pickupAddress: d.pickupAddress,
                    deliveryAddress: d.deliveryAddress,
                    status: newStatus,
                    clientName: d.clientName,
                    clientPhone: d.clientPhone,
                    amount: d.amount,
                    createdAt: d.createdAt,
                    completedAt: newStatus == 'COMPLETED'
                        ? DateTime.now()
                        : d.completedAt,
                    distance: d.distance,
                    estimatedTime: d.estimatedTime,
                  )
                : d,
          )
          .toList();

      await cacheDeliveries(updated);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du cache: $e');
    }
  }
}
