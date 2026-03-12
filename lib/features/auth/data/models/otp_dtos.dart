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
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final hasTokens = (data['accessToken'] ?? json['accessToken']) != null &&
        (data['refreshToken'] ?? json['refreshToken']) != null;
    final nextStep = json['nextStep'] as String? ??
        (hasTokens ? 'COMPLETE' : 'CREATE_PROFILE');

    // CAS 1: Nouveau user (CREATE_PROFILE)
    if (nextStep == 'CREATE_PROFILE') {
      return VerifyOtpResponse(
        message: json['message'] as String? ?? 'OTP verified',
        nextStep: nextStep,
        userId: data['userId']?.toString(),
        tempToken: data['tempToken']?.toString(),
        status: data['status']?.toString(),
      );
    }

    // CAS 2: User existant (COMPLETE) - tokens directs
    return VerifyOtpResponse(
      message: json['message'] as String? ?? 'Login successful',
      nextStep: nextStep,
      accessToken:
          data['accessToken']?.toString() ?? json['accessToken']?.toString(),
      refreshToken:
          data['refreshToken']?.toString() ?? json['refreshToken']?.toString(),
      user: data['user'] != null
          ? UserProfileData.fromJson(data['user'] as Map<String, dynamic>)
          : (json['user'] != null
              ? UserProfileData.fromJson(json['user'] as Map<String, dynamic>)
              : null),
    );
  }

  /// Helpers pour identifier le cas
  bool get isNewUser =>
      nextStep == 'CREATE_PROFILE' ||
      status == 'PENDING_PROFILE' ||
      accessToken == null;

  bool get isExistingUser =>
      nextStep == 'COMPLETE' ||
      (accessToken != null && refreshToken != null && user != null);
}

// ============================================================================
// REQUÊTE 3: CRÉER PROFIL + SÉLECTIONNER DRIVER TYPE
// ============================================================================

class CreateProfileOtpDto {
  final String phone;
  final String fullName;
  final String role;
  final DriverType? driverType;
  final String? avatarUrl;
  final String? preferredLanguage;

  CreateProfileOtpDto({
    required this.phone,
    required this.fullName,
    required this.role,
    this.driverType,
    this.avatarUrl,
    this.preferredLanguage,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'phone': phone,
      'fullName': fullName,
      'role': role,
    };

    if (driverType != null) {
      json['driverType'] = driverType!.toShortString();
    }
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      json['avatarUrl'] = avatarUrl!.trim();
    }
    if (preferredLanguage != null && preferredLanguage!.trim().isNotEmpty) {
      json['preferredLanguage'] = preferredLanguage!.trim();
    }

    return json;
  }
}

class CreateProfileResponse {
  final String message;
  final UserProfileData data;
  final String? accessToken;
  final String? refreshToken;
  final String nextStep;

  CreateProfileResponse({
    required this.message,
    required this.data,
    this.accessToken,
    this.refreshToken,
    required this.nextStep,
  });

  factory CreateProfileResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as Map<String, dynamic>? ?? {};
    final userMap = rawData['user'] is Map<String, dynamic>
        ? rawData['user'] as Map<String, dynamic>
        : rawData;

    return CreateProfileResponse(
      message: json['message']?.toString() ?? 'Profile created',
      data: UserProfileData.fromJson(userMap),
      accessToken:
          rawData['accessToken']?.toString() ?? json['accessToken']?.toString(),
      refreshToken: rawData['refreshToken']?.toString() ??
          json['refreshToken']?.toString(),
      nextStep: json['nextStep']?.toString() ?? 'COMPLETE',
    );
  }
}

class UserProfileData {
  final String id;
  final String fullName;
  final String phone;
  final String role;
  final String? driverType; // Optionnel (seulement pour DRIVER)
  final String? driverAvailabilityStatus;
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
    this.driverAvailabilityStatus,
    required this.status,
    required this.isVerified,
    this.hasActivePass,
    this.createdAt,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    return UserProfileData(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['userId']?.toString() ??
          '',
      fullName: json['fullName']?.toString() ??
          [json['firstName'], json['lastName']]
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .join(' ')
              .trim(),
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CLIENT',
      driverType: json['driverType'] as String?,
      driverAvailabilityStatus: json['driverAvailabilityStatus']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      isVerified: toBool(json['isVerified']),
      hasActivePass: json['hasActivePass'] is bool
          ? json['hasActivePass'] as bool
          : (json['hasActivePass'] == null
              ? null
              : toBool(json['hasActivePass'])),
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Helper pour déterminer la page d'accueil
  String get homeRoute {
    if (role == 'CLIENT') return '/clientHome';

    if (role == 'DRIVER') {
      // VTC -> toujours home VTC
      if (driverType == 'VTC') {
        return '/driver/vtc/home';
      }

      // Pas de pass actif → Achat pass
      if (hasActivePass == false) {
        return '/driver/passes/purchase';
      }

      // MOTO → Accueil livreur MOTO
      if (driverType == 'MOTO') {
        return '/livreurHome';
      }

      // Fallback DRIVER
      return '/livreurHome';
    }

    if (role == 'ADMIN') return '/admin/home';

    // Fallback général
    return '/splash';
  }
}
