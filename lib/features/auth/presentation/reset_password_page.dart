import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/inputs/text_input.dart';
import '../../../core/atoms/buttons/primary_button.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class ResetPasswordPage extends GetView<AuthService> {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

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
                  color: AppColors.primary,
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
                        'Recuperar Senha',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextInputWidget(
                        controller: emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      Obx(() => PrimaryButton(
                        text: 'Enviar Link de Recuperação',
                        isLoading: controller.isLoading.value,
                        onPressed: () async {
                          if (emailController.text.isEmpty) {
                            Get.snackbar(
                              'Campo Obrigatório',
                              'Por favor, informe seu email',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.orange.withOpacity(0.8),
                              colorText: Colors.white,
                            );
                            return;
                          }
                          
                          final success = await controller.requestPasswordReset(
                            email: emailController.text,
                          );
                          
                          if (success) {
                            Get.snackbar(
                              'Sucesso',
                              'Se este email for cadastrado, verifique sua caixa de entrada para receber as instruções de redefinição de senha',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.withOpacity(0.8),
                              colorText: Colors.white,
                              duration: const Duration(seconds: 5),
                            );
                            Get.offAllNamed(AppRoutes.LOGIN);
                          }
                        },
                      )),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Get.back(),
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