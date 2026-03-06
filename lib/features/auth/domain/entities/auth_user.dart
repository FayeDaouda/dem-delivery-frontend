import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String phone;
  final String? fullName;
  final String role; // CLIENT, DRIVER, ADMIN
  final String accessToken;
  final String refreshToken;

  const AuthUser({
    required this.phone,
    this.fullName,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [phone, fullName, role, accessToken, refreshToken];
}
