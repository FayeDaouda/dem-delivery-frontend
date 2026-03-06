import '../../domain/entities/delivery.dart';
import '../../domain/repositories/deliveries_repository.dart';
import '../datasources/deliveries_local_data_source.dart';
import '../datasources/deliveries_remote_data_source.dart';

class DeliveriesRepositoryImpl implements DeliveriesRepository {
  final DeliveriesRemoteDataSource remoteDataSource;
  final DeliveriesLocalDataSource localDataSource;

  DeliveriesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Récupère les livraisons depuis l'API, avec fallback sur le cache local
  @override
  Future<List<Delivery>> fetchDeliveries() async {
    try {
      final deliveries = await remoteDataSource.fetchDeliveries();
      // Mettre en cache les livraisons récupérées
      await localDataSource.cacheDeliveries(deliveries);
      return deliveries;
    } catch (e) {
      // En cas d'erreur réseau, retourner le cache local
      try {
        final cachedDeliveries = await localDataSource.getCachedDeliveries();
        if (cachedDeliveries.isNotEmpty) {
          return cachedDeliveries;
        }
        rethrow; // Re-lancer l'exception si le cache est vide
      } catch (_) {
        rethrow; // Re-lancer l'exception originale
      }
    }
  }

  @override
  Future<Delivery> getDeliveryDetails(String id) async {
    try {
      return await remoteDataSource.getDeliveryDetails(id);
    } catch (e) {
      // Chercher en cache local
      try {
        final cachedDelivery = await localDataSource.getCachedDeliveryById(id);
        if (cachedDelivery != null) {
          return cachedDelivery;
        }
        rethrow;
      } catch (_) {
        rethrow;
      }
    }
  }

  @override
  Future<void> updateDeliveryStatus(String id, String status) async {
    // Mettre à jour immédiatement en cache local
    await localDataSource.updateCachedDeliveryStatus(id, status);

    try {
      // Puis mettre à jour sur le serveur
      await remoteDataSource.updateDeliveryStatus(id, status);
    } catch (e) {
      // En cas d'erreur, la mise à jour locale reste
      rethrow;
    }
  }
}
