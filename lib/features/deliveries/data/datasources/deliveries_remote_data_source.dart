import 'package:dio/dio.dart';

import '../models/delivery_model.dart';

abstract class DeliveriesRemoteDataSource {
  Future<List<DeliveryModel>> fetchDeliveries();
  Future<DeliveryModel> getDeliveryDetails(String id);
  Future<void> updateDeliveryStatus(String id, String status);
}

class DeliveriesRemoteDataSourceImpl implements DeliveriesRemoteDataSource {
  final Dio dio;

  DeliveriesRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<DeliveryModel>> fetchDeliveries() async {
    try {
      final response = await dio.get('/deliveries');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final deliveries = data['data'] is List
            ? (data['data'] as List)
                .map((d) => DeliveryModel.fromJson(d as Map<String, dynamic>))
                .toList()
            : <DeliveryModel>[];
        return deliveries;
      }
      throw Exception('Failed to fetch deliveries');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  @override
  Future<DeliveryModel> getDeliveryDetails(String id) async {
    try {
      final response = await dio.get('/deliveries/$id');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DeliveryModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch delivery details');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> updateDeliveryStatus(String id, String status) async {
    try {
      await dio.put(
        '/deliveries/$id/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}
