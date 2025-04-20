import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/atoms/inputs/text_input.dart';
import '../../../core/atoms/buttons/primary_button.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import 'package:dio/dio.dart';

class TermsPage extends GetView<AuthService> {
  const TermsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Termos de Uso – UniGo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Última atualização: 13/04/2025\n',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Bem-vindo ao UniGo! Ao utilizar este aplicativo, você concorda com os seguintes termos e condições. Por favor, leia com atenção.\n',
                        ),
                        _buildSection(
                          '1. Objetivo do Aplicativo',
                          'O UniGo é um sistema de navegação e localização em tempo real destinado a orientar usuários dentro do campus universitário, facilitando o acesso a salas, departamentos, laboratórios, bibliotecas, auditórios e demais instalações.',
                        ),
                        _buildSection(
                          '2. Aceitação dos Termos',
                          'Ao instalar, acessar ou usar o UniGo, você concorda com estes Termos de Uso e com a nossa Política de Privacidade. Caso não concorde, não utilize o aplicativo.',
                        ),
                        _buildSection(
                          '3. Uso Permitido',
                          'Você se compromete a:\n'
                          '• Utilizar o aplicativo apenas para fins legais e pessoais;\n'
                          '• Não modificar, copiar, distribuir ou comercializar o conteúdo do aplicativo;\n'
                          '• Não utilizar o UniGo para fins maliciosos, como tentar acessar áreas restritas ou manipular dados.',
                        ),
                        _buildSection(
                          '4. Acesso e Disponibilidade',
                          'O UniGo poderá estar indisponível temporariamente devido a manutenções, falhas técnicas ou atualizações. Não garantimos disponibilidade contínua.',
                        ),
                        _buildSection(
                          '5. Coleta de Dados',
                          'O aplicativo pode coletar dados como:\n'
                          '• Localização em tempo real;\n'
                          '• Dados de navegação no app;\n'
                          '• Informações de dispositivo.\n'
                          'Esses dados são usados para melhorar sua experiência e a precisão da navegação. Para mais detalhes, consulte nossa Política de Privacidade.',
                        ),
                        _buildSection(
                          '6. Propriedade Intelectual',
                          'Todo o conteúdo do UniGo, incluindo logotipo, interface, mapas e funcionalidades, é protegido por direitos autorais e pertence à equipe desenvolvedora e/ou à instituição mantenedora.',
                        ),
                        _buildSection(
                          '7. Limitação de Responsabilidade',
                          'O UniGo é uma ferramenta auxiliar de localização. Não nos responsabilizamos por eventuais falhas na navegação, rotas incorretas, atrasos ou erros de localização.',
                        ),
                        _buildSection(
                          '8. Alterações nos Termos',
                          'Estes termos podem ser atualizados a qualquer momento. Recomendamos que você revise regularmente. A continuação do uso do app após mudanças implica aceitação dos novos termos.',
                        ),
                        _buildSection(
                          '9. Suporte',
                          'Em caso de dúvidas ou problemas, entre em contato pelo e-mail: [seuemail@dominio.com]',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            controller.logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Rejeitar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptTerms(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aceitar'),
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  Future<void> _acceptTerms() async {
    try {
      final userData = await controller.storage.getUserData();
      if (userData == null) {
        Get.snackbar(
          'Erro',
          'Dados do usuário não encontrados',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final token = userData['token'];
      final userId = userData['id'];
      
      final response = await controller.dio.post(
        '/auth/accept-terms',
        data: { 'userId': userId },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {  
        userData['termsAccepted'] = true;
        userData['requiresTermsAcceptance'] = false;
        await controller.storage.saveUserData(userData);
        
        Get.offAllNamed(AppRoutes.HOME);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Ocorreu um erro ao aceitar os termos',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
