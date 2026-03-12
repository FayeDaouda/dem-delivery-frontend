import 'package:bloc_test/bloc_test.dart';
import 'package:delivery_express_mobility_frontend/features/auth/domain/usecases/auth_usecases.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<LoginUseCase>(),
  MockSpec<SendOtpUseCase>(),
  MockSpec<VerifyOtpUseCase>(),
  MockSpec<CreateProfileUseCase>(),
  MockSpec<LogoutUseCase>(),
])
import 'auth_bloc_test.mocks.dart';

class MockCreateProfileUseCase extends Mock implements CreateProfileUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockSendOtpUseCase mockSendOtpUseCase;
  late MockVerifyOtpUseCase mockVerifyOtpUseCase;
  late MockCreateProfileUseCase mockCreateProfileUseCase;
  late MockLogoutUseCase mockLogoutUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockSendOtpUseCase = MockSendOtpUseCase();
    mockVerifyOtpUseCase = MockVerifyOtpUseCase();
    mockCreateProfileUseCase = MockCreateProfileUseCase();
    mockLogoutUseCase = MockLogoutUseCase();

    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      sendOtpUseCase: mockSendOtpUseCase,
      verifyOtpUseCase: mockVerifyOtpUseCase,
      createProfileUseCase: mockCreateProfileUseCase,
      logoutUseCase: mockLogoutUseCase,
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'login success -> AuthLoading then AuthSuccess',
      build: () {
        when(mockLoginUseCase.call('+221770000000', 'pass123')).thenAnswer(
          (_) async => {
            'role': 'CLIENT',
            'data': {
              'user': {'fullName': 'Test Client'}
            }
          },
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginEvent(phone: '+221770000000', password: 'pass123'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthSuccess(role: 'CLIENT', userName: 'Test Client'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'login invalid response -> AuthFailure',
      build: () {
        when(mockLoginUseCase.call('+221770000000', 'pass123')).thenAnswer(
          (_) async => {'data': {}},
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginEvent(phone: '+221770000000', password: 'pass123'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(message: 'Réponse invalide du serveur'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'send otp failure -> AuthFailure',
      build: () {
        when(mockSendOtpUseCase.call('+221770000000')).thenThrow(
          Exception('OTP failed'),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSendOtpEvent(phone: '+221770000000')),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'verify otp success -> AuthSuccess',
      build: () {
        when(mockVerifyOtpUseCase.call('+221770000000', '1234')).thenAnswer(
          (_) async => {
            'nextStep': 'COMPLETE',
            'data': {
              'accessToken': 'token_access',
              'refreshToken': 'token_refresh',
              'user': {
                'id': 'u_driver_1',
                'fullName': 'Driver Test',
                'phone': '+221770000000',
                'role': 'DRIVER',
                'driverType': 'VTC',
                'hasActivePass': true,
              }
            }
          },
        );
        return authBloc;
      },
      act: (bloc) => bloc
          .add(const AuthVerifyOtpEvent(phone: '+221770000000', code: '1234')),
      expect: () => [
        const AuthLoading(),
        const AuthSuccess(
          role: 'DRIVER',
          userName: 'Driver Test',
          driverType: 'VTC',
          userId: 'u_driver_1',
          hasActivePass: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'logout -> AuthUnauthenticated',
      build: () {
        when(mockLogoutUseCase.call()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutEvent()),
      expect: () => [
        const AuthUnauthenticated(),
      ],
    );
  });
}
