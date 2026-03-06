import '../../data/models/otp_dtos.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String phone, String password);
  Future<Map<String, dynamic>> sendOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp(String phone, String code);
  Future<bool> refreshSession();
  Future<Map<String, dynamic>> createProfile({
    required String phone,
    required String role,
    String? fullName,
    String? avatar,
  });

  /// Nouveau : Créer profil pour flux OTP-Only avec driverType
  Future<CreateProfileResponse> createProfileOtp({
    required String userId,
    required String fullName,
    required String password,
    required DriverType driverType,
    required String tempToken,
  });

  Future<void> logout();
  Future<String?> getAccessToken();
  Future<String?> getRole();
}
