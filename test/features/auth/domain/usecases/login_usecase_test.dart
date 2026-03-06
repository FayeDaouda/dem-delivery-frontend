import 'package:delivery_express_mobility_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:delivery_express_mobility_frontend/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
])
import 'login_usecase_test.mocks.dart';

void main() {
  late LoginUseCase loginUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(repository: mockAuthRepository);
  });

  test('returns map response when repository login succeeds', () async {
    when(mockAuthRepository.login('+221770000000', 'pass123')).thenAnswer(
      (_) async => {
        'role': 'CLIENT',
        'data': {
          'accessToken': 'at',
          'refreshToken': 'rt',
          'user': {'fullName': 'User 1'}
        }
      },
    );

    final result = await loginUseCase.call('+221770000000', 'pass123');

    expect(result['role'], 'CLIENT');
    verify(mockAuthRepository.login('+221770000000', 'pass123')).called(1);
  });

  test('throws when repository login fails', () async {
    when(mockAuthRepository.login('+221770000000', 'wrong')).thenThrow(
      Exception('Invalid credentials'),
    );

    expect(
      () => loginUseCase.call('+221770000000', 'wrong'),
      throwsA(isA<Exception>()),
    );
  });
}
