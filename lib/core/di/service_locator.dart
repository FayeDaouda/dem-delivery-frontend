import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/deliveries/data/datasources/deliveries_local_data_source.dart';
import '../../features/deliveries/data/datasources/deliveries_remote_data_source.dart';
import '../../features/deliveries/data/repositories/deliveries_repository_impl.dart';
import '../../features/deliveries/domain/repositories/deliveries_repository.dart';
import '../../features/deliveries/domain/usecases/deliveries_usecases.dart';
import '../../features/deliveries/presentation/bloc/deliveries_bloc.dart';
import '../../features/passes/data/datasources/passes_remote_data_source.dart';
import '../../features/passes/data/repositories/pass_repository.dart';
import '../../features/passes/data/repositories/passes_repository_impl.dart';
import '../../features/passes/domain/repositories/passes_repository.dart';
import '../../features/passes/domain/usecases/passes_usecases.dart';
import '../../features/passes/presentation/bloc/pass_bloc.dart';
import '../../features/passes/presentation/cubit/passes_cubit.dart';
import '../../services/delivery_live_service.dart';
import '../services/socket_service.dart';
import '../storage/secure_storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Important: reset pour éviter un état partiel après hot restart/reload
  await getIt.reset();

  // Core Services
  final storage = SecureStorageService();
  getIt.registerSingleton<SecureStorageService>(storage);

  // Dio Configuration
  final dio = Dio(
    BaseOptions(
      baseUrl: "https://dem-delivery-backend.onrender.com",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Add interceptor for token injection
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

  getIt.registerSingleton<Dio>(dio);

  // Socket Service
  final socketService = SocketServiceImpl();
  getIt.registerSingleton<SocketService>(socketService);

  // ============== AUTH FEATURE ==============
  // Remote Data Source
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // Repository
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      storage: getIt<SecureStorageService>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(repository: getIt<AuthRepository>()),
  );
  getIt.registerSingleton<SendOtpUseCase>(
    SendOtpUseCase(repository: getIt<AuthRepository>()),
  );
  getIt.registerSingleton<VerifyOtpUseCase>(
    VerifyOtpUseCase(repository: getIt<AuthRepository>()),
  );
  getIt.registerSingleton<RefreshSessionUseCase>(
    RefreshSessionUseCase(repository: getIt<AuthRepository>()),
  );
  getIt.registerSingleton<CreateProfileUseCase>(
    CreateProfileUseCase(repository: getIt<AuthRepository>()),
  );
  getIt.registerSingleton<LogoutUseCase>(
    LogoutUseCase(repository: getIt<AuthRepository>()),
  );

  // BLoC
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      sendOtpUseCase: getIt<SendOtpUseCase>(),
      verifyOtpUseCase: getIt<VerifyOtpUseCase>(),
      createProfileUseCase: getIt<CreateProfileUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
    ),
  );

  // ============== DELIVERIES FEATURE ==============
  // Remote Data Source
  getIt.registerSingleton<DeliveriesRemoteDataSource>(
    DeliveriesRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // Local Data Source for caching
  getIt.registerSingleton<DeliveriesLocalDataSource>(
    DeliveriesLocalDataSourceImpl(),
  );

  // Repository
  getIt.registerSingleton<DeliveriesRepository>(
    DeliveriesRepositoryImpl(
      remoteDataSource: getIt<DeliveriesRemoteDataSource>(),
      localDataSource: getIt<DeliveriesLocalDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<FetchDeliveriesUseCase>(
    FetchDeliveriesUseCase(repository: getIt<DeliveriesRepository>()),
  );
  getIt.registerSingleton<GetDeliveryDetailsUseCase>(
    GetDeliveryDetailsUseCase(repository: getIt<DeliveriesRepository>()),
  );
  getIt.registerSingleton<UpdateDeliveryStatusUseCase>(
    UpdateDeliveryStatusUseCase(repository: getIt<DeliveriesRepository>()),
  );

  // BLoC
  getIt.registerSingleton<DeliveriesBloc>(
    DeliveriesBloc(
      fetchDeliveriesUseCase: getIt<FetchDeliveriesUseCase>(),
      getDeliveryDetailsUseCase: getIt<GetDeliveryDetailsUseCase>(),
      updateDeliveryStatusUseCase: getIt<UpdateDeliveryStatusUseCase>(),
    ),
  );

  // ============== PASSES FEATURE ==============
  // Remote Data Source
  getIt.registerSingleton<PassesRemoteDataSource>(
    PassesRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // Repository
  getIt.registerSingleton<PassesRepository>(
    PassesRepositoryImpl(
      remoteDataSource: getIt<PassesRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<FetchAvailablePassesUseCase>(
    FetchAvailablePassesUseCase(repository: getIt<PassesRepository>()),
  );
  getIt.registerSingleton<FetchUserPassesUseCase>(
    FetchUserPassesUseCase(repository: getIt<PassesRepository>()),
  );
  getIt.registerSingleton<ActivatePassUseCase>(
    ActivatePassUseCase(repository: getIt<PassesRepository>()),
  );
  getIt.registerSingleton<DeactivatePassUseCase>(
    DeactivatePassUseCase(repository: getIt<PassesRepository>()),
  );
  getIt.registerSingleton<GetPassDetailsUseCase>(
    GetPassDetailsUseCase(repository: getIt<PassesRepository>()),
  );

  // Cubit
  getIt.registerSingleton<PassesCubit>(
    PassesCubit(
      fetchAvailablePassesUseCase: getIt<FetchAvailablePassesUseCase>(),
      fetchUserPassesUseCase: getIt<FetchUserPassesUseCase>(),
      activatePassUseCase: getIt<ActivatePassUseCase>(),
      deactivatePassUseCase: getIt<DeactivatePassUseCase>(),
      getPassDetailsUseCase: getIt<GetPassDetailsUseCase>(),
    ),
  );

  // ============== DELIVERY LIVE SERVICE ==============
  getIt.registerSingleton<DeliveryLiveService>(
    DeliveryLiveService(),
  );

  // ============== PASS BLOC ==============
  getIt.registerSingleton<PassBloc>(
    PassBloc(
      passRepository: PassRepository(dio: getIt<Dio>()),
    ),
  );

  // Validation explicite: doit toujours être disponible avant runApp
  assert(getIt.isRegistered<DeliveryLiveService>());
}
