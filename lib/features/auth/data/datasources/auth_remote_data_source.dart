import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/otp_dtos.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String phone, String password);
  Future<Map<String, dynamic>> sendOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp(String phone, String code);
  Future<Map<String, dynamic>> resendOtp(String phone);
  Future<Map<String, dynamic>> refresh(String refreshToken);
  Future<Map<String, dynamic>> createProfile({
    required String phone,
    required String role,
    String? fullName,
    String? avatar,
  });

  /// Nouveau : Créer profil pour flux OTP-Only avec driverType
  Future<CreateProfileResponse> createProfileOtp({
    required String phone,
    required String fullName,
    required String role,
    DriverType? driverType,
    String? avatarUrl,
    String? preferredLanguage,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Login failed with status ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        throw _handleDioException(e);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await dio.post(
        '/auth/otp/request',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Send OTP failed with status ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        throw _handleDioException(e);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    try {
      final payload = {
        'phone': phone,
        'code': code,
      };
      final response = await dio.post(
        '/auth/otp/verify',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final normalized = _normalizeResponseData(response.data);
        return normalized;
      }
      throw Exception('Verify OTP failed with status ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        throw _handleDioException(e);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> resendOtp(String phone) async {
    try {
      final response = await dio.post(
        '/auth/resend-otp',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Resend OTP failed with status ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        throw _handleDioException(e);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _normalizeResponseData(response.data);
      }

      throw Exception('Refresh failed with status ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        throw _handleDioException(e);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _normalizeResponseData(dynamic rawData) {
    var data = rawData;
    if (data is String) {
      data = _parseJsonString(data);
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'data': data};
  }

  Map<String, dynamic> _parseJsonString(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {'raw': jsonString};
    }
  }

  @override
  Future<Map<String, dynamic>> createProfile({
    required String phone,
    required String role,
    String? fullName,
    String? avatar,
  }) async {
    try {
      final payload = <String, dynamic>{
        'phone': phone,
        'role': role,
      };

      if (fullName != null && fullName.trim().isNotEmpty) {
        payload['fullName'] = fullName.trim();
      }
      if (avatar != null && avatar.trim().isNotEmpty) {
        payload['avatar'] = avatar.trim();
      }

      final response = await dio.post(
        '/auth/otp/create-profile',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(
          'Create profile failed with status ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        throw _handleDioException(e);
      }
      rethrow;
    }
  }

  /// Nouveau : Créer profil pour flux OTP-Only avec driverType
  @override
  Future<CreateProfileResponse> createProfileOtp({
    required String phone,
    required String fullName,
    required String role,
    DriverType? driverType,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    try {
      final dto = CreateProfileOtpDto(
        phone: phone,
        fullName: fullName,
        role: role,
        driverType: driverType,
        avatarUrl: avatarUrl,
        preferredLanguage: preferredLanguage,
      );

      final response = await dio.post(
        '/auth/otp/create-profile',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateProfileResponse.fromJson(response.data);
      }
      throw Exception(
        'Create profile failed with status ${response.statusCode}',
      );
    } catch (e) {
      if (e is DioException) {
        throw _handleDioException(e);
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    // Logout est généralement côté client (clear local storage)
    // Pas d'appel API backend requis pour OTP-only flow
    // Cette implémentation peut être étendue si le backend le nécessite
    return Future.value();
  }

  String _handleDioException(dynamic e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        final error = data['error'];
        if (error is Map) {
          final nestedMessage = error['message'];
          if (nestedMessage is String) return nestedMessage;
          if (nestedMessage is List && nestedMessage.isNotEmpty) {
            return nestedMessage.join('\n');
          }
        }

        final message = data['message'] ?? data['error'] ?? 'Erreur serveur';
        if (message is List && message.isNotEmpty) {
          return message.join('\n');
        }
        return message.toString();
      } else if (data is String) {
        return data;
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Délai d\'attente de connexion dépassé';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Le serveur met trop de temps à répondre';
    }
    return e.message ?? 'Erreur réseau';
  }
}
