import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.phone,
    super.fullName,
    required super.role,
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final user = data['user'] ?? {};

    return AuthUserModel(
      phone: json['phone'] ?? '',
      fullName: user['fullName'],
      role: json['role'] ?? 'CLIENT',
      accessToken: data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'fullName': fullName,
      'role': role,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
