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
  Future<void> logout();
  Future<String?> getAccessToken();
  Future<String?> getRole();
}
