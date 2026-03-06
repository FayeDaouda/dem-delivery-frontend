import '../../domain/entities/pass.dart';

abstract class PassesRepository {
  Future<List<Pass>> fetchAvailablePasses();
  Future<List<Pass>> fetchUserPasses();
  Future<Pass> activatePass(String passId);
  Future<void> deactivatePass(String passId);
  Future<Pass> getPassDetails(String passId);
}
