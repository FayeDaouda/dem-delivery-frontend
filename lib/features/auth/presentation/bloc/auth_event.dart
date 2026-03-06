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

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}
