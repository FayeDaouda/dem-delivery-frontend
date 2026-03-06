import 'package:dio/dio.dart';

import '../models/pass_model.dart';

abstract class PassesRemoteDataSource {
  Future<List<PassModel>> fetchAvailablePasses();
  Future<List<PassModel>> fetchUserPasses();
  Future<PassModel> activatePass(String passId);
  Future<void> deactivatePass(String passId);
  Future<PassModel> getPassDetails(String passId);
}

class PassesRemoteDataSourceImpl implements PassesRemoteDataSource {
  final Dio dio;

  PassesRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<PassModel>> fetchAvailablePasses() async {
    try {
      final response = await dio.get('/passes/available');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final passes = data['data'] is List
            ? (data['data'] as List)
                .map((p) => PassModel.fromJson(p as Map<String, dynamic>))
                .toList()
            : <PassModel>[];
        return passes;
      }
      throw Exception('Failed to fetch available passes');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<PassModel>> fetchUserPasses() async {
    try {
      final response = await dio.get('/passes/user');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final passes = data['data'] is List
            ? (data['data'] as List)
                .map((p) => PassModel.fromJson(p as Map<String, dynamic>))
                .toList()
            : <PassModel>[];
        return passes;
      }
      throw Exception('Failed to fetch user passes');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  @override
  Future<PassModel> activatePass(String passId) async {
    try {
      final response = await dio.post('/passes/$passId/activate');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PassModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to activate pass');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> deactivatePass(String passId) async {
    try {
      await dio.post('/passes/$passId/deactivate');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  @override
  Future<PassModel> getPassDetails(String passId) async {
    try {
      final response = await dio.get('/passes/$passId');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PassModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch pass details');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}
