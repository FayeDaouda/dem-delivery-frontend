import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<Map<String, dynamic>> call(String phone, String password) async {
    return await repository.login(phone, password);
  }
}

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase({required this.repository});

  Future<Map<String, dynamic>> call(String phone) async {
    return await repository.sendOtp(phone);
  }
}

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase({required this.repository});

  Future<Map<String, dynamic>> call(String phone, String code) async {
    return await repository.verifyOtp(phone, code);
  }
}

class RefreshSessionUseCase {
  final AuthRepository repository;

  RefreshSessionUseCase({required this.repository});

  Future<bool> call() async {
    return await repository.refreshSession();
  }
}

class CreateProfileUseCase {
  final AuthRepository repository;

  CreateProfileUseCase({required this.repository});

  Future<Map<String, dynamic>> call({
    required String phone,
    required String role,
    String? fullName,
    String? avatar,
  }) async {
    return await repository.createProfile(
      phone: phone,
      role: role,
      fullName: fullName,
      avatar: avatar,
    );
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase({required this.repository});

  Future<void> call() async {
    return await repository.logout();
  }
}
