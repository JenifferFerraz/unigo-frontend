import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/inputs/text_input.dart';
import '../../../core/atoms/buttons/primary_button.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthService auth;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    auth = Get.find<AuthService>();
    emailController.addListener(_recomputeValidity);
    passwordController.addListener(_recomputeValidity);
  }

  @override
  void dispose() {
    emailController.removeListener(_recomputeValidity);
    passwordController.removeListener(_recomputeValidity);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _recomputeValidity() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final emailOk = RegExp(r'^.+@.+\..+$').hasMatch(email);
    final passOk = password.isNotEmpty && password.length >= 6;
    final next = emailOk && passOk;
    if (next != _canSubmit) {
      setState(() => _canSubmit = next);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Image.asset(
                  'assets/images/logo.png',
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
                        isLoading: auth.isLoading.value,
                        enabled: _canSubmit,
                        onPressed: () async {
                          if (!_canSubmit) {
                            Get.snackbar('Campos inválidos', 'Preencha email válido e senha (mín. 6 caracteres).', snackPosition: SnackPosition.BOTTOM);
                            return;
                          }
                          await auth.login(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                          );
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