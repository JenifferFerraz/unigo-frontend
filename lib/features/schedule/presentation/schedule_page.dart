import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/auth_service.dart';
import '../../home/presentation/components/sidebar.dart';

class SchedulePage extends StatefulWidget {
  final AuthService _authService = Get.find<AuthService>();

  SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePage();
}

class _SchedulePage extends State<SchedulePage> {
  Widget _buildDaySection(String day, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...items,
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String subject, String location, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: const TextStyle(fontSize: 15)),
              Text(location, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
          Text(time, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
  String selectedPeriod = '3º';
  final List<String> periods = ['1º', '2º', '3º', '4º', '5º'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        title: const Text('Horário de Aulas'),
        backgroundColor: const Color(0xFF3C3CC0),
        foregroundColor: Colors.white,
      ),
      drawer: Sidebar(),
      body: Obx(() {
        final user = widget._authService.currentUser.value;
        if (user == null) {
          return const Center(child: Text('Usuário não encontrado'));
        }
        return Center(
          child: Container(
            width: 430,
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filtro de período (apenas um dropdown)
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => selectedPeriod = v!),
                ),
                const SizedBox(height: 24),
                // Listagem de horários em cards verticais por dia
                Expanded(
                  child: ListView(
                    children: [
                      _buildDaySection('SEGUNDA-FEIRA', [
                        _buildScheduleItem('Internet das Coisas', 'Bloco A - 1º Piso - 114', '19:00 - 19:50'),
                        _buildScheduleItem('Internet das Coisas', 'Bloco A - 1º Piso - 114', '19:50 - 20:40'),
                        _buildScheduleItem('Internet das Coisas', 'Bloco A - 1º Piso - 114', '21:00 - 21:50'),
                        _buildScheduleItem('Internet das Coisas', 'Bloco A - 1º Piso - 114', '21:50 - 22:40'),
                      ]),
                      _buildDaySection('TERÇA-FEIRA', [
                        _buildScheduleItem('Habilidades Complementares', 'Bloco H - 1º Piso - 105', '19:00 - 19:50'),
                        _buildScheduleItem('Habilidades Complementares', 'Bloco H - 1º Piso - 105', '19:50 - 20:40'),
                        _buildScheduleItem('Habilidades Complementares', 'Bloco H - 1º Piso - 105', '21:00 - 21:50'),
                        _buildScheduleItem('Habilidades Complementares', 'Bloco H - 1º Piso - 105', '21:50 - 22:40'),
                      ]),
                      _buildDaySection('QUARTA-FEIRA', [
                        _buildScheduleItem('Segurança da Informação', 'Bloco H - 1º Piso - 114', '19:00 - 19:50'),
                        _buildScheduleItem('Segurança da Informação', 'Bloco H - 1º Piso - 114', '19:50 - 20:40'),
                        _buildScheduleItem('Segurança da Informação', 'Bloco H - 1º Piso - 114', '21:00 - 21:50'),
                        _buildScheduleItem('Segurança da Informação', 'Bloco H - 1º Piso - 114', '21:50 - 22:40'),
                      ]),
                      // Adicione mais dias conforme necessário
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Observações',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 10),
                const Text('• Os horários podem sofrer alterações', style: TextStyle(fontSize: 15)),
                const Text('• Em caso de dúvidas, consulte a coordenação', style: TextStyle(fontSize: 15)),
                const Text('• Fique atento aos feriados e recessos', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Removido: tabela de horários e métodos relacionados
}
