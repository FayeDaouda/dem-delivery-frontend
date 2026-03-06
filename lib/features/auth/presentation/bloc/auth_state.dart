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

  const AuthOtpVerified({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthSuccess extends AuthState {
  final String role;
  final String? userName;

  const AuthSuccess({
    required this.role,
    this.userName,
  });

  @override
  List<Object?> get props => [role, userName];
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
