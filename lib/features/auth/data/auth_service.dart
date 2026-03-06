// lib/features/auth/data/auth_service.dart
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthService {
  final ApiClient apiClient;
  final SecureStorageService storage;

  AuthService({required this.apiClient, required this.storage});

  /// Envoie OTP
  Future<bool> sendOtp(String phone) async {
    try {
      final response = await apiClient.dio.post(
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

  /// Vérifie OTP et stocke token + rôle
  Future<String?> verifyOtp(String phone, String code) async {
    try {
      final response = await apiClient.dio.post('/auth/otp/verify', data: {
        'phone': phone,
        'code': code,
      });
      print("VERIFY OTP RESPONSE: ${response.statusCode} / ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = response.data['data']['accessToken'];
        final refreshToken = response.data['data']['refreshToken'];
        final role = response.data['role'];

        await storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: role,
        );

        return role;
      }
    } catch (e) {
      print("VERIFY OTP ERROR: $e");
    }
    return null;
  }

  /// Login classique avec phone + password, stocke token + rôle
  Future<String?> login(String phone, String password) async {
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      print("LOGIN RESPONSE: ${response.statusCode} / ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = response.data['data']['accessToken'];
        final refreshToken = response.data['data']['refreshToken'];
        final role = response.data['role'];

        await storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: role,
        );

        return role;
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
    }
    return null;
  }
}
