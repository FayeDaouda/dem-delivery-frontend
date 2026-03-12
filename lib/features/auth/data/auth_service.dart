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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RequestOtpResponse.fromJson(response.data);
      }
      throw Exception('Failed to send OTP: ${response.statusCode}');
    } catch (e) {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VerifyOtpResponse.fromJson(response.data);
      }
      throw Exception('Failed to verify OTP: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Étape 3: Créer profil avec driverType (MOTO ou VTC)
  /// Retourne accessToken + refreshToken + driverType
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

      final response = await apiClient.dio.post(
        '/auth/otp/create-profile',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final profileResponse = CreateProfileResponse.fromJson(response.data);

        // Sauvegarder les tokens si présents
        if (profileResponse.accessToken != null &&
            profileResponse.refreshToken != null) {
          await storage.saveTokens(
            accessToken: profileResponse.accessToken!,
            refreshToken: profileResponse.refreshToken!,
            role: profileResponse.data.role,
            driverType: profileResponse.data.driverType,
          );
        }

        return profileResponse;
      }
      throw Exception('Failed to create profile: ${response.statusCode}');
    } catch (e) {
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
      return null;
    }
    return null;
  }
}
