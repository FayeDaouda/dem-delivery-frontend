part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent();
}

class AuthOtpVerified extends AuthState {
  final String phone;
  final String? userId; // Pour flux OTP-Only
  final String? tempToken; // Pour flux OTP-Only

  const AuthOtpVerified({
    required this.phone,
    this.userId,
    this.tempToken,
  });

  @override
  List<Object?> get props => [phone, userId, tempToken];
}

class AuthSuccess extends AuthState {
  final String role;
  final String? userName;
  final String? driverType; // MOTO ou VTC

  const AuthSuccess({
    required this.role,
    this.userName,
    this.driverType,
  });

  @override
  List<Object?> get props => [role, userName, driverType];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
