part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginEvent extends AuthEvent {
  final String phone;
  final String password;

  const AuthLoginEvent({
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, password];
}

class AuthSendOtpEvent extends AuthEvent {
  final String phone;

  const AuthSendOtpEvent({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOtpEvent extends AuthEvent {
  final String phone;
  final String code;

  const AuthVerifyOtpEvent({
    required this.phone,
    required this.code,
  });

  @override
  List<Object?> get props => [phone, code];
}

/// Événement ancien (non-utilisé dans flux OTP-Only)
class AuthCreateProfileEvent extends AuthEvent {
  final String phone;
  final String role;
  final String? fullName;
  final String? avatar;

  const AuthCreateProfileEvent({
    required this.phone,
    required this.role,
    this.fullName,
    this.avatar,
  });

  @override
  List<Object?> get props => [phone, role, fullName, avatar];
}

/// Nouveau événement pour flux OTP-Only avec sélection MOTO/VTC
class AuthCreateProfileOtpEvent extends AuthEvent {
  final String userId;
  final String fullName;
  final String password;
  final String driverType; // "MOTO" ou "VTC"
  final String tempToken;

  const AuthCreateProfileOtpEvent({
    required this.userId,
    required this.fullName,
    required this.password,
    required this.driverType,
    required this.tempToken,
  });

  @override
  List<Object?> get props => [userId, fullName, password, driverType, tempToken];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}
