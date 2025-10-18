import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/atoms/inputs/text_input.dart';
import '../../../core/atoms/inputs/dropdown_input.dart';
import '../../../core/atoms/buttons/primary_button.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/upload_image_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterPage extends GetView<AuthService> {  
  
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.fetchCourses();
    
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final studentIdController = TextEditingController();
  final selectedCourse = Rxn<int>();
  final selectedShift = Rxn<String>();
  final selectedGender = Rxn<String>();
  final courses = controller.courses;

    final shifts = [
      'matutino',
      'vespertino',
      'noturno',
      'integral',
    ];

   

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
            child: Container(
              width: double.infinity,
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Criar Conta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                   
                    TextInputWidget(
                      controller: nameController,
                      label: 'Nome Completo',
                    ),
                    const SizedBox(height: 16),
                    TextInputWidget(
                      controller: emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextInputWidget(
                      controller: passwordController,
                      label: 'Senha',
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Obx(() => DropdownInputWidget<int>(
                      label: 'Curso',
                      hint: 'Selecione o curso',
                      value: selectedCourse.value,
                      items: courses.map((course) => DropdownMenuItem(
                        value: course['id'] as int,
                        child: Text(course['name'] as String),
                      )).toList(),
                      onChanged: (value) => selectedCourse.value = value,
                    )),
                    const SizedBox(height: 16),
                    Obx(() => DropdownInputWidget<String>(
                      label: 'Turno',
                      hint: 'Selecione o turno',
                      value: selectedShift.value,
                      items: shifts.map((shift) => DropdownMenuItem(
                        value: shift,
                        child: Text(shift.capitalize!),
                      )).toList(),
                      onChanged: (value) => selectedShift.value = value,
                    )),
                    const SizedBox(height: 16),
                    TextInputWidget(
                      controller: studentIdController,
                      label: 'Matrícula',
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Cadastrar',
                      onPressed: () async {
                        try {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              studentIdController.text.isEmpty ||
                              selectedCourse.value == null ||
                              selectedShift.value == null ||
                              selectedGender.value == null) {
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
                          final studentProfile = {
                            'studentId': studentIdController.text,
                            'courseId': selectedCourse.value,
                            'shift': selectedShift.value,
                            'gender': selectedGender.value,
                          };
                          Get.dialog(
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 32),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Criando sua conta...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Aguarde um momento',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            barrierDismissible: false,
                            barrierColor: Colors.black.withOpacity(0.3),
                          );
                          final success = await controller.register(
                            name: nameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                            role: 'student',
                            studentProfile: studentProfile,
                          );
                          Get.back();
                          if (success) {
                            Get.snackbar(
                              'Conta Criada!',
                              'Por favor, faça login para acessar o sistema',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.green[100],
                              colorText: Colors.green[900],
                              duration: const Duration(seconds: 3),
                            );
                            nameController.clear();
                            emailController.clear();
                            passwordController.clear();
                            studentIdController.clear();
                            selectedCourse.value = null;
                            selectedShift.value = null;
                            selectedGender.value = null;
                            await Future.delayed(const Duration(seconds: 2));
                            Get.until((route) => route.settings.name == AppRoutes.LOGIN);
                          } else {
                            throw 'Não foi possível criar sua conta';
                          }
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Erro no Cadastro',
                            'Ocorreu um erro ao criar sua conta. Tente novamente.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red[100],
                            colorText: Colors.red[900],
                            duration: const Duration(seconds: 5),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Já tem uma conta? Faça login',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}