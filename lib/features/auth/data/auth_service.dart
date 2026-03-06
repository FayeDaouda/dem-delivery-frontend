// lib/features/auth/data/auth_service.dart
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models/otp_dtos.dart';

class AuthService {
  final ApiClient apiClient;
  final SecureStorageService storage;

  AuthService({required this.apiClient, required this.storage});

  /// Étape 1: Envoie OTP
  Future<RequestOtpResponse> sendOtp(String phone) async {
    try {
      final dto = RequestOtpDto(phone: phone);
      final response = await apiClient.dio.post(
        '/auth/otp/request',
        data: dto.toJson(),
      );
      print("🔔 SEND OTP RESPONSE: ${response.statusCode} / ${response.data}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return RequestOtpResponse.fromJson(response.data);
      }
      throw Exception('Failed to send OTP: ${response.statusCode}');
    } catch (e) {
      print("❌ SEND OTP ERROR: $e");
      rethrow;
    }
  }

  /// Étape 2: Vérifie OTP - Retourne userId + tempToken (PAS de tokens JWT)
  Future<VerifyOtpResponse> verifyOtp(String phone, String code) async {
    try {
      final dto = VerifyOtpDto(phone: phone, code: code);
      final response = await apiClient.dio.post(
        '/auth/otp/verify',
        data: dto.toJson(),
      );
      print("✅ VERIFY OTP RESPONSE: ${response.statusCode} / ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VerifyOtpResponse.fromJson(response.data);
      }
      throw Exception('Failed to verify OTP: ${response.statusCode}');
    } catch (e) {
      print("❌ VERIFY OTP ERROR: $e");
      rethrow;
    }
  }

  /// Étape 3: Créer profil avec driverType (MOTO ou VTC)
  /// Retourne accessToken + refreshToken + driverType
  Future<CreateProfileResponse> createProfileOtp({
    required String userId,
    required String fullName,
    required String password,
    required DriverType driverType,
    required String tempToken,
  }) async {
    try {
      final dto = CreateProfileOtpDto(
        userId: userId,
        fullName: fullName,
        password: password,
        driverType: driverType,
        tempToken: tempToken,
      );
      
      final response = await apiClient.dio.post(
        '/auth/otp/create-profile',
        data: dto.toJson(),
      );
      print("🎉 CREATE PROFILE RESPONSE: ${response.statusCode} / ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final profileResponse = CreateProfileResponse.fromJson(response.data);
        
        // Sauvegarder les tokens
        await storage.saveTokens(
          accessToken: profileResponse.accessToken,
          refreshToken: profileResponse.refreshToken,
          role: profileResponse.data.role,
          driverType: profileResponse.data.driverType,
        );

        return profileResponse;
      }
      throw Exception('Failed to create profile: ${response.statusCode}');
    } catch (e) {
      print("❌ CREATE PROFILE ERROR: $e");
      rethrow;
    }
  }

  /// Login classique avec phone + password (ancienne méthode, stocke token + rôle)
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
