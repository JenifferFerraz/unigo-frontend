import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:unigo_mobile/data/services/auth_service.dart';
import 'package:unigo_mobile/data/services/storage_service.dart';
import 'package:unigo_mobile/core/config/env_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Generate mocks
@GenerateMocks([Dio, StorageService])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockDio mockDio;
  late MockStorageService mockStorageService;

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();

    mockDio = MockDio();
    mockStorageService = MockStorageService();

    // Mock StorageService
    when(mockStorageService.init()).thenAnswer((_) async => mockStorageService);
    Get.put<StorageService>(mockStorageService);

    // Create AuthService with mocked Dio
    authService = AuthService();
    authService.dio = mockDio;
  });

  tearDown(() {
    Get.reset();
  });

  group('AuthService - Password Reset', () {
    group('requestPasswordReset', () {
      test('should return true when request is successful', () async {
        // Arrange
        when(mockDio.post(
          '/auth/forgot-password',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'Email sent'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
        ));

        // Act
        final result = await authService.requestPasswordReset(
          email: 'test@example.com',
        );

        // Assert
        expect(result, isTrue);
        verify(mockDio.post(
          '/auth/forgot-password',
          data: {'email': 'test@example.com'},
        )).called(1);
      });

      test('should return false when request fails', () async {
        // Arrange
        when(mockDio.post(
          '/auth/forgot-password',
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/auth/forgot-password'),
          ),
        ));

        // Act
        final result = await authService.requestPasswordReset(
          email: 'test@example.com',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should set isLoading to true during request', () async {
        // Arrange
        when(mockDio.post(
          '/auth/forgot-password',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Future.delayed(
          const Duration(milliseconds: 100),
          () => Response(
            data: {'message': 'Email sent'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/forgot-password'),
          ),
        ));

        // Act
        final future = authService.requestPasswordReset(
          email: 'test@example.com',
        );

        // Assert - isLoading should be true during request
        expect(authService.isLoading.value, isTrue);

        await future;

        // Assert - isLoading should be false after request
        expect(authService.isLoading.value, isFalse);
      });
    });

    group('confirmPasswordReset', () {
      test('should return true when reset is successful', () async {
        // Arrange
        when(mockDio.post(
          '/auth/reset-password',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'Password successfully reset'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/reset-password'),
        ));

        // Act
        final result = await authService.confirmPasswordReset(
          token: 'valid-token-123',
          newPassword: 'newpassword123',
        );

        // Assert
        expect(result, isTrue);
        verify(mockDio.post(
          '/auth/reset-password',
          data: {
            'token': 'valid-token-123',
            'newPassword': 'newpassword123',
          },
        )).called(1);
      });

      test('should return false when token is invalid', () async {
        // Arrange
        when(mockDio.post(
          '/auth/reset-password',
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          response: Response(
            statusCode: 400,
            data: {'message': 'Invalid or expired reset token'},
            requestOptions: RequestOptions(path: '/auth/reset-password'),
          ),
        ));

        // Act
        final result = await authService.confirmPasswordReset(
          token: 'invalid-token',
          newPassword: 'newpassword123',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false when token is expired', () async {
        // Arrange
        when(mockDio.post(
          '/auth/reset-password',
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          response: Response(
            statusCode: 400,
            data: {'message': 'Invalid or expired reset token'},
            requestOptions: RequestOptions(path: '/auth/reset-password'),
          ),
        ));

        // Act
        final result = await authService.confirmPasswordReset(
          token: 'expired-token',
          newPassword: 'newpassword123',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should set isLoading to true during request', () async {
        // Arrange
        when(mockDio.post(
          '/auth/reset-password',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Future.delayed(
          const Duration(milliseconds: 100),
          () => Response(
            data: {'message': 'Password successfully reset'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/reset-password'),
          ),
        ));

        // Act
        final future = authService.confirmPasswordReset(
          token: 'valid-token',
          newPassword: 'newpassword123',
        );

        // Assert - isLoading should be true during request
        expect(authService.isLoading.value, isTrue);

        await future;

        // Assert - isLoading should be false after request
        expect(authService.isLoading.value, isFalse);
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        when(mockDio.post(
          '/auth/reset-password',
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act
        final result = await authService.confirmPasswordReset(
          token: 'valid-token',
          newPassword: 'newpassword123',
        );

        // Assert
        expect(result, isFalse);
        expect(authService.isLoading.value, isFalse);
      });
    });
  });
}

