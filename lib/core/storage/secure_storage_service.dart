import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    String? driverType,
  }) async {
    print('💾 SAVING TO STORAGE: role=$role, driverType=$driverType');
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    await _storage.write(key: 'role', value: role);
    if (driverType != null) {
      await _storage.write(key: 'driverType', value: driverType);
    }
    print('✅ SAVED TO STORAGE SUCCESSFULLY');
  }

  Future<String?> getAccessToken() async =>
      await _storage.read(key: 'accessToken');
  Future<String?> getRefreshToken() async =>
      await _storage.read(key: 'refreshToken');
  Future<String?> getRole() async {
    final role = await _storage.read(key: 'role');
    print('📖 READING ROLE FROM STORAGE: $role');
    return role;
  }

  Future<String?> getDriverType() async =>
      await _storage.read(key: 'driverType');

  // User
  Future<void> saveUser({
    required String phone,
    String? name,
    String? fullName,
    bool? isOnline,
    bool? hasActivePass,
    String? passExpiresAt,
  }) async {
    await _storage.write(key: 'user_phone', value: phone);
    if (name != null) await _storage.write(key: 'user_name', value: name);
    if (fullName != null)
      await _storage.write(key: 'user_full_name', value: fullName);
    if (isOnline != null) {
      await _storage.write(key: 'driver_is_online', value: isOnline.toString());
    }
    if (hasActivePass != null) {
      await _storage.write(
          key: 'driver_has_active_pass', value: hasActivePass.toString());
    }
    if (passExpiresAt != null) {
      await _storage.write(key: 'driver_pass_expires_at', value: passExpiresAt);
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    final phone = await _storage.read(key: 'user_phone');
    final name = await _storage.read(key: 'user_name');
    final fullName = await _storage.read(key: 'user_full_name');
    final isOnline = await _storage.read(key: 'driver_is_online');
    final hasActivePass = await _storage.read(key: 'driver_has_active_pass');
    final passExpiresAt = await _storage.read(key: 'driver_pass_expires_at');

    if (phone != null) {
      return {
        'phone': phone,
        'name': name,
        'fullName': fullName,
        'isOnline': isOnline,
        'hasActivePass': hasActivePass,
        'passExpiresAt': passExpiresAt,
      };
    }
    return null;
  }

  // Driver specific data
  Future<void> saveDriverData({
    String? userId,
    String? status,
    String? verificationDeadline,
    String? kycStatus,
  }) async {
    if (userId != null) await _storage.write(key: 'driver_id', value: userId);
    if (status != null)
      await _storage.write(key: 'driver_status', value: status);
    if (verificationDeadline != null) {
      await _storage.write(
          key: 'driver_verification_deadline', value: verificationDeadline);
    }
    if (kycStatus != null) {
      await _storage.write(key: 'driver_kyc_status', value: kycStatus);
    }
  }

  Future<Map<String, String?>> getDriverData() async {
    return {
      'id': await _storage.read(key: 'driver_id'),
      'status': await _storage.read(key: 'driver_status'),
      'verificationDeadline':
          await _storage.read(key: 'driver_verification_deadline'),
      'kycStatus': await _storage.read(key: 'driver_kyc_status'),
    };
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
