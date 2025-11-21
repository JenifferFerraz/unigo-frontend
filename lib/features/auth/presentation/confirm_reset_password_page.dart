import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/inputs/text_input.dart';
import '../../../core/atoms/buttons/primary_button.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class ConfirmResetPasswordPage extends GetView<AuthService> {
  const ConfirmResetPasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    // Obtém o token da query string da URL atual
    String? token;
    try {
      final uri = Uri.tryParse(Uri.base.toString());
      if (uri != null && uri.queryParameters.containsKey('token')) {
        token = uri.queryParameters['token'];
      }
    } catch (e) {
      // Ignora erros ao tentar parsear a URL
    }

    // Se não tiver token, redireciona para a página de solicitação de reset
    if (token == null || token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Token Inválido',
          'Link de redefinição inválido ou expirado',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        Get.offAllNamed(AppRoutes.RESET_PASSWORD);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed(AppRoutes.ACCESS_SELECTION),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Image.asset(
                  'assets/images/Logo.png',
                  height: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 48),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 40.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Redefinir Senha',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Digite sua nova senha',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextInputWidget(
                        controller: passwordController,
                        label: 'Nova Senha',
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      TextInputWidget(
                        controller: confirmPasswordController,
                        label: 'Confirmar Nova Senha',
                        obscureText: true,
                      ),
                      const SizedBox(height: 32),
                      Obx(() => PrimaryButton(
                        text: 'Redefinir Senha',
                        isLoading: controller.isLoading.value,
                        onPressed: token == null || token.isEmpty
                            ? () {
                                Get.snackbar(
                                  'Token Inválido',
                                  'Link de redefinição inválido ou expirado',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              }
                            : () async {
                                if (passwordController.text.isEmpty ||
                                    confirmPasswordController.text.isEmpty) {
                                  Get.snackbar(
                                    'Campos Incompletos',
                                    'Por favor, preencha todos os campos',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.orange.withOpacity(0.8),
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                if (passwordController.text.length < 6) {
                                  Get.snackbar(
                                    'Senha Inválida',
                                    'A senha deve ter pelo menos 6 caracteres',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.orange.withOpacity(0.8),
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                if (passwordController.text !=
                                    confirmPasswordController.text) {
                                  Get.snackbar(
                                    'Senhas Não Conferem',
                                    'As senhas digitadas não são iguais',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.orange.withOpacity(0.8),
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final success = await controller.confirmPasswordReset(
                                  token: token!,
                                  newPassword: passwordController.text,
                                );

                                if (success) {
                                  Get.snackbar(
                                    'Sucesso',
                                    'Senha redefinida com sucesso! Você já pode fazer login',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green.withOpacity(0.8),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 4),
                                  );
                                  Get.offAllNamed(AppRoutes.LOGIN);
                                }
                              },
                      )),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Get.offAllNamed(AppRoutes.LOGIN),
                        child: Text(
                          'Voltar para o login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

