import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/presentation/components/sidebar.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        title: const Text('Provas'),
        backgroundColor: const Color(0xFF3C3CC0),
        foregroundColor: Colors.white,
      ),
      drawer: Sidebar(),
      body: Center(
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: 'Ciclo 01',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Ciclo 01', child: Text('Ciclo 01')),
                    DropdownMenuItem(value: 'Ciclo 02', child: Text('Ciclo 02')),
                  ],
                  onChanged: (v) {},
                ),
                const SizedBox(height: 24),
                const Text('Aplicação de Provas 1ª VA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                _buildExamDay('TERÇA-FEIRA', '16/09/2025', [
                  _buildExamItem('11476 - Data Science', '20:15 - 21:15', '8º'),
                  _buildExamItem('11300 - Internet das Coisas', '21:30 - 22:30', '8º'),
                ]),
                _buildExamDay('QUARTA-FEIRA', '17/09/2025', [
                  _buildExamItem('11302 - Segurança da Informação', '19:00 - 20:00', '8º'),
                ]),
                _buildExamDay('QUINTA-FEIRA', '18/09/2025', [
                  _buildExamItem('11303 - Desenvolvimento Mobile', '20:15 - 21:15', '8º'),
                ]),
                _buildExamDay('TERÇA-FEIRA', '23/09/2025', [
                  _buildExamItem('111477 - Habilidades Complementares', '19:00 - 22:40', '8º'),
                ]),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C3CC0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Inscrição', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamDay(String day, String date, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$day    $date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ...items,
        ],
      ),
    );
  }

  Widget _buildExamItem(String subject, String time, String grade) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: const TextStyle(fontSize: 15)),
              Text(time, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
          Text(grade, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
