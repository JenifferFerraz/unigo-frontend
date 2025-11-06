import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/atoms/inputs/text_input.dart';
import '../../../core/atoms/buttons/primary_button.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/location_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';


class LoginPage extends GetView<AuthService> {
  bool _hasInjection(String value) {
    final pattern = RegExp(r'select\s|insert\s|update\s|delete\s|<script>|<html>|<body>', caseSensitive: false);
    return pattern.hasMatch(value);
  }
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Image.asset(
                  'assets/images/Logo.png',
                  height: 120,
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
                      TextInputWidget(
                        controller: emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      TextInputWidget(
                        controller: passwordController,
                        label: 'Senha',
                        obscureText: true,
                      ),
                      const SizedBox(height: 32),
                      Obx(() => PrimaryButton(
                        text: 'Entrar',
                        isLoading: controller.isLoading.value,
                        onPressed: () async {
                          if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                            Get.snackbar(
                              'Campos Incompletos',
                              'Por favor, preencha todos os campos obrigatórios',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.orange[100],
                              colorText: Colors.orange[900],
                              duration: const Duration(seconds: 4),
                            );
                            return;
                          }
                          if (_hasInjection(emailController.text) || _hasInjection(passwordController.text)) {
                            Get.snackbar(
                              'Valor inválido',
                              'Os campos não podem conter comandos SQL ou HTML.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red[100],
                              colorText: Colors.red[900],
                              duration: const Duration(seconds: 4),
                            );
                            return;
                          }
                          final success = await controller.login(
                            email: emailController.text,
                            password: passwordController.text,
                          );
                          if (success) {
                            Get.offAllNamed(AppRoutes.HOME);
                          }
                        },
                      )),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Get.toNamed(AppRoutes.RESET_PASSWORD),
                            child: Text(
                              'Esqueceu a senha?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.toNamed(AppRoutes.REGISTER),
                            child: Text(
                              'Cadastre-se',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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