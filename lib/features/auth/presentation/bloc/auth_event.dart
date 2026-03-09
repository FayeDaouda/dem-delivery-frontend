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
  final String phone;
  final String fullName;
  final String role; // "CLIENT" ou "DRIVER"
  final String? driverType; // "MOTO" ou "VTC"
  final String? avatarUrl;
  final String? preferredLanguage;

  const AuthCreateProfileOtpEvent({
    required this.phone,
    required this.fullName,
    required this.role,
    this.driverType,
    this.avatarUrl,
    this.preferredLanguage,
  });

  @override
  List<Object?> get props =>
      [phone, fullName, role, driverType, avatarUrl, preferredLanguage];
}

class AuthResendOtpEvent extends AuthEvent {
  final String phone;

  const AuthResendOtpEvent({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}
