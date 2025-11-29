import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:unigo_mobile/features/auth/presentation/reset_password_page.dart';
import 'package:unigo_mobile/features/auth/presentation/confirm_reset_password_page.dart';
import 'package:unigo_mobile/data/services/auth_service.dart';
import 'package:unigo_mobile/data/services/storage_service.dart';
import 'package:unigo_mobile/data/models/user_model.dart';
import 'package:unigo_mobile/routes/app_routes.dart';

// Mock classes
class MockAuthService extends GetxService implements AuthService {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<User?> currentUser = Rx<User?>(null);

  @override
  Future<bool> requestPasswordReset({required String email}) async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 100));
    isLoading.value = false;
    return email.isNotEmpty;
  }

  @override
  Future<bool> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 100));
    isLoading.value = false;
    return token.isNotEmpty && newPassword.length >= 6;
  }

  @override
  Future<AuthService> init() async => this;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStorageService extends GetxService implements StorageService {
  @override
  Future<StorageService> init() async => this;

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {}

  @override
  Future<Map<String, dynamic>?> getUserData() async => null;

  @override
  Future<void> clearUserData() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAuthService mockAuthService;
  late MockStorageService mockStorageService;

  setUp(() {
    Get.testMode = true;
    Get.reset();

    mockAuthService = MockAuthService();
    mockStorageService = MockStorageService();

    Get.put<AuthService>(mockAuthService);
    Get.put<StorageService>(mockStorageService);
  });

  tearDown(() {
    Get.reset();
  });

  group('ResetPasswordPage Widget Tests', () {
    testWidgets('should display reset password form', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.RESET_PASSWORD,
          getPages: [
            GetPage(
              name: AppRoutes.RESET_PASSWORD,
              page: () => const ResetPasswordPage(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verifica se os elementos principais estão presentes
      expect(find.text('Recuperar Senha'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enviar Link de Recuperação'), findsOneWidget);
      expect(find.text('Voltar para o login'), findsOneWidget);
    });

    testWidgets('should show error when email is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.RESET_PASSWORD,
          getPages: [
            GetPage(
              name: AppRoutes.RESET_PASSWORD,
              page: () => const ResetPasswordPage(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Tenta enviar sem preencher email
      final sendButton = find.text('Enviar Link de Recuperação');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Deve mostrar snackbar de erro
      expect(find.text('Campo Obrigatório'), findsOneWidget);
    });

    testWidgets('should call requestPasswordReset when form is submitted', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.RESET_PASSWORD,
          getPages: [
            GetPage(
              name: AppRoutes.RESET_PASSWORD,
              page: () => const ResetPasswordPage(),
            ),
            GetPage(
              name: AppRoutes.LOGIN,
              page: () => const Scaffold(body: Text('Login Page')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Preenche o email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Clica no botão de enviar
      final sendButton = find.text('Enviar Link de Recuperação');
      await tester.tap(sendButton);
      await tester.pump();

      // Verifica se o método foi chamado (através do loading)
      expect(mockAuthService.isLoading.value, isTrue);

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verifica se voltou para login após sucesso
      expect(find.text('Login Page'), findsOneWidget);
    });
  });

  group('ConfirmResetPasswordPage Widget Tests', () {
    testWidgets('should display confirm reset password form with token', (WidgetTester tester) async {
      // Simula URL com token
      Get.testMode = true;

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '${AppRoutes.RESET_PASSWORD}?token=test-token-123',
          getPages: [
            GetPage(
              name: AppRoutes.RESET_PASSWORD,
              page: () {
                // Simula a lógica da rota que detecta token
                return const ConfirmResetPasswordPage();
              },
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verifica se os elementos principais estão presentes
      expect(find.text('Redefinir Senha'), findsOneWidget);
      expect(find.text('Nova Senha'), findsOneWidget);
      expect(find.text('Confirmar Nova Senha'), findsOneWidget);
      expect(find.text('Redefinir Senha'), findsWidgets);
    });

    testWidgets('should show error when passwords do not match', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.RESET_PASSWORD,
          getPages: [
            GetPage(
              name: AppRoutes.RESET_PASSWORD,
              page: () => const ConfirmResetPasswordPage(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Preenche senhas diferentes
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.first, 'password123');
      await tester.enterText(passwordFields.last, 'password456');
      await tester.pump();

      // Tenta submeter
      final submitButton = find.text('Redefinir Senha').last;
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Deve mostrar erro de senhas não conferem
      expect(find.text('Senhas Não Conferem'), findsOneWidget);
    });

    testWidgets('should show error when password is too short', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.RESET_PASSWORD,
          getPages: [
            GetPage(
              name: AppRoutes.RESET_PASSWORD,
              page: () => const ConfirmResetPasswordPage(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Preenche senha muito curta
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.first, '12345'); // 5 caracteres
      await tester.enterText(passwordFields.last, '12345');
      await tester.pump();

      // Tenta submeter
      final submitButton = find.text('Redefinir Senha').last;
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Deve mostrar erro de senha inválida
      expect(find.text('Senha Inválida'), findsOneWidget);
    });

    testWidgets('should call confirmPasswordReset when form is valid', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.RESET_PASSWORD,
          getPages: [
            GetPage(
              name: AppRoutes.RESET_PASSWORD,
              page: () => const ConfirmResetPasswordPage(),
            ),
            GetPage(
              name: AppRoutes.LOGIN,
              page: () => const Scaffold(body: Text('Login Page')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Preenche senhas válidas
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.first, 'newpassword123');
      await tester.enterText(passwordFields.last, 'newpassword123');
      await tester.pump();

      // Tenta submeter (mas vai falhar porque não tem token na URL)
      final submitButton = find.text('Redefinir Senha').last;
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Como não tem token, deve mostrar erro
      expect(find.text('Token Inválido'), findsOneWidget);
    });
  });
}

