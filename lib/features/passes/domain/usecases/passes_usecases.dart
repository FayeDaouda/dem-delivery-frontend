import '../../domain/entities/pass.dart';
import '../../domain/repositories/passes_repository.dart';

class FetchAvailablePassesUseCase {
  final PassesRepository repository;

  FetchAvailablePassesUseCase({required this.repository});

  Future<List<Pass>> call() async {
    return await repository.fetchAvailablePasses();
  }
}

class FetchUserPassesUseCase {
  final PassesRepository repository;

  FetchUserPassesUseCase({required this.repository});

  Future<List<Pass>> call() async {
    return await repository.fetchUserPasses();
  }
}

class ActivatePassUseCase {
  final PassesRepository repository;

  ActivatePassUseCase({required this.repository});

  Future<Pass> call(String passId) async {
    return await repository.activatePass(passId);
  }
}

class DeactivatePassUseCase {
  final PassesRepository repository;

  DeactivatePassUseCase({required this.repository});

  Future<void> call(String passId) async {
    return await repository.deactivatePass(passId);
  }
}

class GetPassDetailsUseCase {
  final PassesRepository repository;

  GetPassDetailsUseCase({required this.repository});

  Future<Pass> call(String passId) async {
    return await repository.getPassDetails(passId);
  }
}
