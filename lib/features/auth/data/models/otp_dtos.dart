/// DTOs pour le flux OTP-Only avec sélection MOTO/VTC

// ============================================================================
// ENUMS
// ============================================================================

enum DriverType { moto, vtc }

extension DriverTypeExtension on DriverType {
  String toShortString() => toString().split('.').last.toUpperCase();

  static DriverType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MOTO':
        return DriverType.moto;
      case 'VTC':
        return DriverType.vtc;
      default:
        throw ArgumentError('Invalid driver type: $value');
    }
  }
}

// ============================================================================
// REQUÊTE 1: DEMANDER OTP
// ============================================================================

class RequestOtpDto {
  final String phone;

  RequestOtpDto({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

class RequestOtpResponse {
  final String message;
  final bool isExistingUser;
  final String nextStep;
  final OtpInfo? otp;

  RequestOtpResponse({
    required this.message,
    required this.isExistingUser,
    required this.nextStep,
    this.otp,
  });

  factory RequestOtpResponse.fromJson(Map<String, dynamic> json) {
    return RequestOtpResponse(
      message: json['message'] as String,
      isExistingUser: json['isExistingUser'] as bool? ?? false,
      nextStep: json['nextStep'] as String? ?? 'VERIFY_OTP',
      otp: json['otp'] != null ? OtpInfo.fromJson(json['otp']) : null,
    );
  }
}

class OtpInfo {
  final String channel;
  final int codeLength;
  final int expiresInSeconds;

  OtpInfo({
    required this.channel,
    required this.codeLength,
    required this.expiresInSeconds,
  });

  factory OtpInfo.fromJson(Map<String, dynamic> json) {
    return OtpInfo(
      channel: json['channel'] as String? ?? 'sms',
      codeLength: json['codeLength'] as int? ?? 6,
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 300,
    );
  }
}

// ============================================================================
// REQUÊTE 2: VÉRIFIER OTP
// ============================================================================

class VerifyOtpDto {
  final String phone;
  final String code;

  VerifyOtpDto({required this.phone, required this.code});

  Map<String, dynamic> toJson() => {'phone': phone, 'code': code};
}

/// Réponse de vérification OTP - Gère 2 cas:
/// CAS 1: Nouveau user → nextStep=CREATE_PROFILE, userId+tempToken fournis
/// CAS 2: User existant → nextStep=COMPLETE, tokens+user data fournis
class VerifyOtpResponse {
  final String message;
  final String nextStep;

  // Cas 1: Nouveau user (nextStep=CREATE_PROFILE)
  final String? userId;
  final String? tempToken;
  final String? status;

  // Cas 2: User existant (nextStep=COMPLETE)
  final String? accessToken;
  final String? refreshToken;
  final UserProfileData? user;

  VerifyOtpResponse({
    required this.message,
    required this.nextStep,
    this.userId,
    this.tempToken,
    this.status,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  /// Factory qui gère les 2 formats de réponse backend
  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final nextStep = json['nextStep'] as String? ?? 'UNKNOWN';

    // CAS 1: Nouveau user (CREATE_PROFILE)
    if (nextStep == 'CREATE_PROFILE') {
      final data = json['data'] as Map<String, dynamic>?;
      return VerifyOtpResponse(
        message: json['message'] as String? ?? 'OTP verified',
        nextStep: nextStep,
        userId: data?['userId'] as String?,
        tempToken: data?['tempToken'] as String?,
        status: data?['status'] as String?,
      );
    }

    // CAS 2: User existant (COMPLETE) - tokens directs
    return VerifyOtpResponse(
      message: json['message'] as String? ?? 'Login successful',
      nextStep: nextStep,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] != null
          ? UserProfileData.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Helpers pour identifier le cas
  bool get isNewUser => nextStep == 'CREATE_PROFILE';
  bool get isExistingUser => nextStep == 'COMPLETE' || accessToken != null;
}

// ============================================================================
// REQUÊTE 3: CRÉER PROFIL + SÉLECTIONNER DRIVER TYPE
// ============================================================================

class CreateProfileOtpDto {
  final String userId;
  final String fullName;
  final String password;
  final DriverType driverType;
  final String tempToken;

  CreateProfileOtpDto({
    required this.userId,
    required this.fullName,
    required this.password,
    required this.driverType,
    required this.tempToken,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'password': password,
        'driverType': driverType.toShortString(),
        'tempToken': tempToken,
      };
}

class CreateProfileResponse {
  final String message;
  final UserProfileData data;
  final String accessToken;
  final String refreshToken;
  final String nextStep;

  CreateProfileResponse({
    required this.message,
    required this.data,
    required this.accessToken,
    required this.refreshToken,
    required this.nextStep,
  });

  factory CreateProfileResponse.fromJson(Map<String, dynamic> json) {
    return CreateProfileResponse(
      message: json['message'] as String,
      data: UserProfileData.fromJson(json['data'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      nextStep: json['nextStep'] as String? ?? 'PURCHASE_PASS',
    );
  }
}

class UserProfileData {
  final String id;
  final String fullName;
  final String phone;
  final String role;
  final String? driverType; // Optionnel (seulement pour DRIVER)
  final String status;
  final bool isVerified;
  final bool? hasActivePass; // Important pour navigation DRIVER
  final String? createdAt;

  UserProfileData({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.driverType,
    required this.status,
    required this.isVerified,
    this.hasActivePass,
    this.createdAt,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      driverType: json['driverType'] as String?,
      status: json['status'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      hasActivePass: json['hasActivePass'] as bool?,
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Helper pour déterminer la page d'accueil
  String get homeRoute {
    if (role == 'CLIENT') return '/clientHome';

    if (role == 'DRIVER') {
      // Pas de pass actif → Achat pass
      if (hasActivePass == false) {
        return '/driver/passes/purchase';
      }

      // MOTO → Accueil livreur MOTO
      if (driverType == 'MOTO') {
        return '/livreurHome';
      }

      // VTC → Accueil VTC
      if (driverType == 'VTC') {
        return '/driver/vtc/home';
      }

      // Fallback DRIVER
      return '/livreurHome';
    }

    if (role == 'ADMIN') return '/admin/home';

    // Fallback général
    return '/splash';
  }
}
