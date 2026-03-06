import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/otp_dtos.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final CreateProfileUseCase createProfileUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.createProfileUseCase,
    required this.logoutUseCase,
  }) : super(const AuthInitial()) {
    on<AuthLoginEvent>(_onLoginEvent);
    on<AuthSendOtpEvent>(_onSendOtpEvent);
    on<AuthVerifyOtpEvent>(_onVerifyOtpEvent);
    on<AuthCreateProfileEvent>(_onCreateProfileEvent);
    on<AuthCreateProfileOtpEvent>(_onCreateProfileOtpEvent);
    on<AuthLogoutEvent>(_onLogoutEvent);
  }

  Future<void> _onLoginEvent(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await loginUseCase(event.phone, event.password);

      final role = response['role']?.toString();
      final data = response['data'];
      final user = data?['user'];
      final userName = user?['fullName']?.toString();

      if (role != null) {
        emit(AuthSuccess(role: role, userName: userName));
      } else {
        emit(const AuthFailure(message: 'Réponse invalide du serveur'));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onSendOtpEvent(
    AuthSendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await sendOtpUseCase(event.phone);
      emit(const AuthOtpSent());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onVerifyOtpEvent(
    AuthVerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await verifyOtpUseCase(event.phone, event.code);
      print('🔍 VERIFY OTP RESPONSE: $response');

      // Flux OTP-Only: Extraire userId et tempToken
      final userId = response['userId']?.toString();
      final tempToken = response['tempToken']?.toString();

      // Ancien flux: Extraire role depuis tokens JWT
      final data = response['data'];
      final user = data is Map<String, dynamic> ? data['user'] : null;
      final role = response['role']?.toString() ??
          (data is Map<String, dynamic> ? data['role']?.toString() : null) ??
          (user is Map<String, dynamic> ? user['role']?.toString() : null);
      final userName =
          user is Map<String, dynamic> ? user['fullName']?.toString() : null;

      print('🔍 EXTRACTED ROLE: $role');
      print('🔍 EXTRACTED userId: $userId, tempToken: $tempToken');
      print('🔍 USER DATA: $user');

      // Cas 1: Ancien utilisateur - Retourner role JWT directement
      if (role != null && role.isNotEmpty) {
        emit(AuthSuccess(role: role, userName: userName));
      }
      // Cas 2: Nouveau utilisateur OTP-Only - Aller à étape profil
      else if (userId != null && tempToken != null) {
        emit(AuthOtpVerified(
          phone: event.phone,
          userId: userId,
          tempToken: tempToken,
        ));
      }
      // Fallback
      else {
        emit(AuthOtpVerified(phone: event.phone));
      }
    } catch (e) {
      print('❌ VERIFY OTP ERROR: $e');
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onCreateProfileEvent(
    AuthCreateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await createProfileUseCase(
        phone: event.phone,
        role: event.role,
        fullName: event.fullName,
        avatar: event.avatar,
      );

      final role = response['role']?.toString() ?? event.role;
      final data = response['data'];
      final user = data?['user'];
      final userName = user?['fullName']?.toString() ?? event.fullName;

      emit(AuthSuccess(role: role, userName: userName));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  /// Nouveau handler pour flux OTP-Only avec driverType (MOTO/VTC)
  Future<void> _onCreateProfileOtpEvent(
    AuthCreateProfileOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final driverTypeEnum = DriverTypeExtension.fromString(event.driverType);
      
      final response = await createProfileUseCase.createProfileOtp(
        userId: event.userId,
        fullName: event.fullName,
        password: event.password,
        driverType: driverTypeEnum,
        tempToken: event.tempToken,
      );

      // Extraction des données de la réponse
      final role = response.data.role;
      final userName = response.data.fullName;
      final driverType = response.data.driverType;

      print('✅ PROFILE CRÉÉ: role=$role, driverType=$driverType');
      
      emit(AuthSuccess(
        role: role,
        userName: userName,
        driverType: driverType,
      ));
    } catch (e) {
      print('❌ CREATE PROFILE OTP ERROR: $e');
      emit(AuthFailure(message: 'Erreur lors de la création du profil: $e'));
    }
  }

  Future<void> _onLogoutEvent(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await logoutUseCase();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }
}
