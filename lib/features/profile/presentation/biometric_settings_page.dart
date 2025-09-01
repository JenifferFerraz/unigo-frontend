import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/buttons/primary_button.dart';
import '../../../data/services/biometric_service.dart';
import '../../../core/constants/app_colors.dart';

class BiometricSettingsPage extends GetView<BiometricService> {
  const BiometricSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Biometria'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login com Impressão Digital',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Use sua impressão digital para fazer login rapidamente',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() => SwitchListTile(
                      title: const Text('Ativar Biometria'),
                      subtitle: const Text('Permitir login com impressão digital'),
                      value: controller.isBiometricEnabled.value,
                      onChanged: (value) {
                        controller.toggleBiometric(value);
                      },
                      activeColor: AppColors.primary,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Status da biometria
            Obx(() {
              if (controller.isBiometricAvailable.value) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status da Biometria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Dispositivo compatível'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              controller.isBiometricEnabled.value
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: controller.isBiometricEnabled.value
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.isBiometricEnabled.value
                                  ? 'Biometria ativada'
                                  : 'Biometria desativada',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Biometria não disponível',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Seu dispositivo não suporta autenticação biométrica ou não há impressões digitais cadastradas.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }),
            
            const SizedBox(height: 24),
            
            // Botão de teste
            Obx(() {
              if (controller.isBiometricAvailable.value && 
                  controller.isBiometricEnabled.value) {
                return SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Testar Biometria',
                    onPressed: () async {
                      final success = await controller.authenticateWithBiometrics();
                      if (success) {
                        Get.snackbar(
                          'Sucesso',
                          'Autenticação biométrica funcionando!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            const Spacer(),
            
            // Informações adicionais
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Informações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                                         Text(
                       '• A biometria só estará disponível após o primeiro login com email e senha\n'
                       '• Suas impressões digitais são armazenadas apenas no seu dispositivo\n'
                       '• Você pode desativar esta funcionalidade a qualquer momento',
                       style: TextStyle(color: Colors.blue.shade700),
                     ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 