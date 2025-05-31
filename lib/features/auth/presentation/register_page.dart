import 'package:flutter/material.dart';
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

class RegisterPage extends GetView<AuthService> {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.fetchCourses();
    
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final cpfController = TextEditingController();
    final studentIdController = TextEditingController();
    final phoneController = TextEditingController();
    final selectedCourse = Rxn<int>();
    final selectedShift = Rxn<String>();
    final selectedGender = Rxn<String>();
    final avatarUrl = ''.obs;   
    final courses = controller.courses;

    final shifts = [
      'matutino',
      'vespertino',
      'noturno',
      'integral',
    ];

    final genders = [
      'male',
      'female',
      'other',
      'prefer_not_to_say',
    ];

    return Scaffold(
      backgroundColor: AppColors.primary,
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
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            
                            if (image != null) {
                              Get.snackbar(
                                'Aguarde', 
                                'Fazendo upload da imagem...',
                                snackPosition: SnackPosition.TOP,
                                duration: const Duration(seconds: 2),
                              );
                              
                              final url = await UploadImagensService.to.uploadImage(image);
                              
                              if (url != null) {
                                avatarUrl.value = url.toString();
                                Get.snackbar(
                                  'Sucesso', 
                                  'Imagem carregada com sucesso',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.green[100],
                                  colorText: Colors.green[900],
                                );
                              } else {
                                throw 'Falha ao carregar imagem';
                              }
                            }
                          } catch (e) {
                            Get.snackbar(
                              'Erro', 
                              'Não foi possível carregar a imagem: ${e.toString()}',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.red[100],
                              colorText: Colors.red[900],
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: Obx(() => CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl.value.isNotEmpty
                                ? NetworkImage(avatarUrl.value)
                                : null,
                            child: avatarUrl.value.isEmpty
                                ? const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: AppColors.primary,
                                  )
                                : null,
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    TextInputWidget(
                      controller: cpfController,
                      label: 'CPF',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Obx(() => DropdownInputWidget<String>(
                      label: 'Gênero',
                      hint: 'Selecione o gênero',
                      value: selectedGender.value,
                      items: genders.map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender == 'male' ? 'Masculino' 
                            : gender == 'female' ? 'Feminino'
                            : gender == 'other' ? 'Outro'
                            : 'Prefiro não dizer'),
                      )).toList(),
                      onChanged: (value) => selectedGender.value = value,
                    )),
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
                    const SizedBox(height: 16),
                    TextInputWidget(
                      controller: phoneController,
                      label: 'Telefone',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      onPressed: () async {
                        try {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              cpfController.text.isEmpty ||
                              studentIdController.text.isEmpty ||
                              phoneController.text.isEmpty ||
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
                            'phone': phoneController.text,
                            'courseId': selectedCourse.value,
                            'shift': selectedShift.value,
                            'gender': selectedGender.value,
                          };

                          Get.dialog(
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                            barrierDismissible: false,
                          );

                          final success = await controller.register(
                            name: nameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                            cpf: cpfController.text,
                            avatar: avatarUrl.value,
                            role: 'student',
                            studentProfile: studentProfile,
                          );

                          Get.back();

                          if (success) {
                            Get.snackbar(
                              'Sucesso!',
                              'Cadastro realizado com sucesso',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.green[100],
                              colorText: Colors.green[900],
                            );
                            await Future.delayed(const Duration(seconds: 1));
                            Get.offAllNamed(AppRoutes.HOME);
                          } else {
                            throw 'Falha ao realizar cadastro';
                          }
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Erro no Cadastro',
                            e.toString().contains('duplicate key')
                                ? 'Email ou CPF já cadastrado'
                                : 'Ocorreu um erro ao realizar o cadastro: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red[100],
                            colorText: Colors.red[900],
                            duration: const Duration(seconds: 5),
                          );
                        }
                      },
                      text: 'Cadastrar',
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
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