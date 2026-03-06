import '../../domain/entities/pass.dart';
import '../../domain/repositories/passes_repository.dart';
import '../datasources/passes_remote_data_source.dart';

class PassesRepositoryImpl implements PassesRepository {
  final PassesRemoteDataSource remoteDataSource;

  PassesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Pass>> fetchAvailablePasses() async {
    return await remoteDataSource.fetchAvailablePasses();
  }

  @override
  Future<List<Pass>> fetchUserPasses() async {
    return await remoteDataSource.fetchUserPasses();
  }

  @override
  Future<Pass> activatePass(String passId) async {
    return await remoteDataSource.activatePass(passId);
  }

  @override
  Future<void> deactivatePass(String passId) async {
    await remoteDataSource.deactivatePass(passId);
  }

  @override
  Future<Pass> getPassDetails(String passId) async {
    return await remoteDataSource.getPassDetails(passId);
  }
}
