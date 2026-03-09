import 'package:flutter/foundation.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/otp_dtos.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      // Format phone number
      final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';

      final response = await remoteDataSource.login(formattedPhone, password);

      await _saveSessionFromResponse(response, fallbackPhone: formattedPhone);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';
      final response = await remoteDataSource.sendOtp(formattedPhone);
      debugPrint('📨 SEND OTP RESPONSE: $response');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    try {
      final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';
      final response = await remoteDataSource.verifyOtp(formattedPhone, code);

      debugPrint('📡 RAW VERIFY OTP RESPONSE: $response');

      // Extraire le rôle de différentes sources possibles
      String? extractedRole = response['role']?.toString();

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final user = data['user'];
        debugPrint('👤 USER IN DATA: $user');

        // Essayer d'extraire depuis data.user.role ou data.role
        if (extractedRole == null && user is Map<String, dynamic>) {
          extractedRole = user['role']?.toString();
          debugPrint('🔑 ROLE FROM user.role: $extractedRole');
        }

        if (extractedRole == null) {
          extractedRole = data['role']?.toString();
          debugPrint('🔑 ROLE FROM data.role: $extractedRole');
        }

        // IMPORTANT: Remettre le rôle au niveau racine pour que AuthBloc le trouve
        if (extractedRole != null && extractedRole.isNotEmpty) {
          response['role'] = extractedRole;
          debugPrint('✅ Set role at root level: $extractedRole');
        }
      }

      debugPrint('✅ FINAL RESPONSE WITH ROLE: ${response['role']}');

      final normalizedData = response['data'];
      final hasSessionTokens = normalizedData is Map<String, dynamic> &&
          normalizedData['accessToken'] != null &&
          normalizedData['refreshToken'] != null;

      if (hasSessionTokens) {
        await _saveSessionFromResponse(response, fallbackPhone: formattedPhone);
      } else {
        debugPrint(
          'ℹ️ VERIFY_OTP returned no session tokens (probablement CREATE_PROFILE), session non sauvegardée à cette étape.',
        );
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> refreshSession() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await remoteDataSource.refresh(refreshToken);
      final user = await storage.getUser();
      final fallbackPhone = user?['phone'];

      await _saveSessionFromResponse(
        response,
        fallbackPhone: fallbackPhone,
      );

      final newAccessToken = await storage.getAccessToken();
      return newAccessToken != null && newAccessToken.isNotEmpty;
    } catch (e) {
      debugPrint('Erreur refresh session: $e');
      await storage.clear();
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> createProfile({
    required String phone,
    required String role,
    String? fullName,
    String? avatar,
  }) async {
    try {
      final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';
      final response = await remoteDataSource.createProfile(
        phone: formattedPhone,
        role: role,
        fullName: fullName,
        avatar: avatar,
      );

      final data = response['data'];
      final user = data is Map<String, dynamic> ? data['user'] : null;
      final backendRole = user is Map<String, dynamic>
          ? user['role']?.toString()
          : (data is Map<String, dynamic> ? data['role']?.toString() : null);

      if (backendRole != null && backendRole.isNotEmpty) {
        response['role'] = backendRole;
        debugPrint('✅ Role from backend create-profile: $backendRole');
      } else if (response['role'] == null ||
          response['role'].toString().isEmpty) {
        response['role'] = role;
        debugPrint('⚠️ Backend role absent, fallback to selected role: $role');
      }

      debugPrint('📨 CREATE PROFILE RESPONSE: $response');

      await _saveSessionFromResponse(response, fallbackPhone: formattedPhone);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Appeler l'endpoint logout du backend
      await remoteDataSource.logout();
    } catch (e) {
      // Continuer avec la déconnexion locale même si le backend échoue
      debugPrint('Erreur logout backend: $e');
    }
    // Vider le stockage local
    await storage.clear();
  }

  @override
  Future<String?> getAccessToken() async {
    return await storage.getAccessToken();
  }

  @override
  Future<String?> getRole() async {
    return await storage.getRole();
  }

  Future<void> _saveSessionFromResponse(
    Map<String, dynamic> response, {
    String? fallbackPhone,
  }) async {
    try {
      // Gérer les cas où 'data' peut être un Map ou null
      final data = response['data'];
      if (data == null) {
        debugPrint('⚠️ Pas de data dans la réponse');
        return;
      }

      // Vérifier si data est bien un Map
      if (data is! Map<String, dynamic>) {
        debugPrint('⚠️ data n\'est pas un Map: $data');
        return;
      }

      final user = data['user'];
      final roleFromUser =
          user is Map<String, dynamic> ? user['role']?.toString() : null;
      final driverTypeFromUser =
          user is Map<String, dynamic> ? user['driverType']?.toString() : null;
      final roleFromData = data['role']?.toString();
      final role = response['role']?.toString() ??
          roleFromUser ??
          roleFromData ??
          await storage.getRole();

      debugPrint('💾 SAVING SESSION - Role from response: ${response['role']}');
      debugPrint('💾 SAVING SESSION - Role from user: $roleFromUser');
      debugPrint('💾 SAVING SESSION - Role from data: $roleFromData');
      debugPrint('💾 SAVING SESSION - Final role to save: $role');

      final accessToken = data['accessToken']?.toString();
      final refreshToken =
          data['refreshToken']?.toString() ?? await storage.getRefreshToken();
      final persistedPhone = fallbackPhone?.trim();

      debugPrint('🎫 Access Token present: ${accessToken != null}');
      debugPrint('🔄 Refresh Token present: ${refreshToken != null}');
      debugPrint('👤 User data: $user');

      final userName = user is Map ? user['fullName']?.toString() : null;
      final userPhone = user is Map
          ? user['phone']?.toString() ?? persistedPhone
          : persistedPhone;

      if (role != null && accessToken != null && refreshToken != null) {
        debugPrint('✅ Saving tokens with role: $role');
        await storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: role,
          driverType: driverTypeFromUser,
        );

        if (userPhone != null && userPhone.isNotEmpty) {
          await storage.saveUser(
            phone: userPhone,
            name: userName,
            fullName: user is Map ? user['fullName']?.toString() : null,
            isOnline: user is Map && user['isOnline'] is bool
                ? user['isOnline'] as bool
                : null,
            hasActivePass: user is Map && user['hasActivePass'] is bool
                ? user['hasActivePass'] as bool
                : null,
            passExpiresAt:
                user is Map ? user['passExpiresAt']?.toString() : null,
          );
        }

        // Si c'est un driver, sauvegarder les données spécifiques
        if ((role == 'DRIVER' || role == 'LIVREUR') &&
            user is Map<String, dynamic>) {
          await storage.saveDriverData(
            userId: user['id']?.toString(),
            status: user['status']?.toString(),
            verificationDeadline: user['verificationDeadline']?.toString(),
            kycStatus: user['kycStatus']?.toString(),
          );
          debugPrint(
              '🚗 Driver data saved: status=${user['status']}, kycStatus=${user['kycStatus']}');
        }
      } else {
        debugPrint(
            '❌ Missing required data: role=$role, accessToken=$accessToken, refreshToken=$refreshToken');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde de la session: $e');
    }
  }

  /// Nouvelle méthode: Créer profil pour flux OTP-Only avec driverType
  @override
  Future<CreateProfileResponse> createProfileOtp({
    required String phone,
    required String fullName,
    required String role,
    DriverType? driverType,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    try {
      debugPrint('🎉 Calling remoteDataSource.createProfileOtp...');
      final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';

      final response = await remoteDataSource.createProfileOtp(
        phone: formattedPhone,
        fullName: fullName,
        role: role,
        driverType: driverType,
        avatarUrl: avatarUrl,
        preferredLanguage: preferredLanguage,
      );

      // Sauvegarder la session
      await _saveSessionFromResponse(
        response.toJson(),
        fallbackPhone: formattedPhone,
      );

      debugPrint(
          '✅ Profile créé avec role=$role, driverType=${driverType?.toShortString()}');

      return response;
    } catch (e) {
      debugPrint('❌ CREATE PROFILE OTP ERROR: $e');
      rethrow;
    }
  }
}

extension CreateProfileResponseToJson on CreateProfileResponse {
  Map<String, dynamic> toJson() => {
        'message': message,
        'data': {
          'user': {
            'id': data.id,
            'fullName': data.fullName,
            'phone': data.phone,
            'role': data.role,
            'driverType': data.driverType,
            'driverAvailabilityStatus': data.driverAvailabilityStatus,
            'status': data.status,
            'isVerified': data.isVerified,
            'hasActivePass': data.hasActivePass,
            'createdAt': data.createdAt,
          },
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'role': data.role,
        },
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'nextStep': nextStep,
        'role': data.role,
      };
}
