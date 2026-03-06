// lib/core/network/api_client.dart
import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService storage;

  ApiClient({required this.storage})
      : dio = Dio(
          BaseOptions(
            baseUrl: "https://dem-delivery-backend.onrender.com",
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

  // Envoi OTP
  Future<bool> sendOtp(String phone) async {
    try {
      final response = await dio.post(
        '/auth/otp/request',
        data: {'phone': phone},
      );
      print("SEND OTP RESPONSE: ${response.statusCode} / ${response.data}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("SEND OTP ERROR: $e");
      return false;
    }
  }

  // Vérification OTP
  Future<Map<String, dynamic>?> verifyOtp(String phone, String code) async {
    try {
      final response = await dio.post('/auth/otp/verify', data: {
        'phone': phone,
        'code': code,
      });
      print("VERIFY OTP RESPONSE: ${response.statusCode} / ${response.data}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } catch (e) {
      print("VERIFY OTP ERROR: $e");
    }
    return null;
  }

  // Login
  Future<Map<String, dynamic>?> login(String phone, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      print("LOGIN RESPONSE: ${response.statusCode} / ${response.data}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
    }
    return null;
  }

  // Register
  Future<Map<String, dynamic>?> register(
    String phone,
    String password,
    String fullName,
    String role,
  ) async {
    try {
      final response = await dio.post('/auth/user/register', data: {
        'phone': phone,
        'password': password,
        'fullName': fullName,
        'role': role,
      });
      print("REGISTER RESPONSE: ${response.statusCode} / ${response.data}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } catch (e) {
      print("REGISTER ERROR: $e");
    }
    return null;
  }
}
