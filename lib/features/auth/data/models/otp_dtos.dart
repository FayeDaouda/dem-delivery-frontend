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

class VerifyOtpResponse {
  final String message;
  final String userId;
  final String status;
  final String nextStep;
  final String tempToken;

  VerifyOtpResponse({
    required this.message,
    required this.userId,
    required this.status,
    required this.nextStep,
    required this.tempToken,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      message: json['message'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String? ?? 'PENDING_PROFILE',
      nextStep: json['nextStep'] as String? ?? 'CREATE_PROFILE',
      tempToken: json['tempToken'] as String,
    );
  }
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
  final String driverType;
  final String status;
  final bool isVerified;
  final String createdAt;

  UserProfileData({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.driverType,
    required this.status,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      driverType: json['driverType'] as String,
      status: json['status'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );
  }
}
