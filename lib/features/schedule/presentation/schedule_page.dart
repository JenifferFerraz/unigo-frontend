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
  String selectedPeriod = '3º';
  String selectedShift = 'Matutino';

  final List<String> periods = ['1º', '2º', '3º', '4º', '5º'];
  final List<String> shifts = ['Matutino', 'Noturno'];

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

        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 40),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações do Curso',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          const SizedBox(height: 12),
                          const Text('Curso: Ciência da Computação', style: TextStyle(fontSize: 16)),
                          Row(
                            children: [
                              const Text('Turno:', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: selectedShift,
                                items: shifts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (v) => setState(() => selectedShift = v!),
                              ),
                              const SizedBox(width: 24),
                              const Text('Período:', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: selectedPeriod,
                                items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                                onChanged: (v) => setState(() => selectedPeriod = v!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Grade de Horários',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 24,
                                headingRowColor: MaterialStateProperty.resolveWith<Color?>((states) => const Color(0xFF3C3CC0).withOpacity(0.1)),
                                dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) => states.contains(MaterialState.selected) ? Colors.blue[50] : Colors.white),
                                columns: _getColumns(),
                                rows: _buildScheduleRowsWithActions(context),
                              ),
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
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<DataColumn> _getColumns() {
    if (selectedShift == 'Noturno') {
      return const [
        DataColumn(label: Text('Horário', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Segunda', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Terça', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Quarta', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Quinta', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Sexta', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
      ];
    } else {
      return const [
        DataColumn(label: Text('Horário', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Segunda', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Terça', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Quarta', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Quinta', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Sexta', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
      ];
    }
  }

  List<DataRow> _buildScheduleRowsWithActions(BuildContext context) {
    if (selectedShift == 'Noturno') {
      final noturno = {
        '1º': [
          ['19:00 - 21:00', 'Cálculo I', 'Física I', 'Algoritmos', 'Matemática Discreta', 'Inglês Técnico'],
          ['21:30 - 22:40', 'Cálculo I', 'Física I', 'Algoritmos', 'Matemática Discreta', 'Inglês Técnico'],
        ],
        '2º': [
          ['19:00 - 21:00', 'Cálculo II', 'Física II', 'Estrut. Dados', 'Banco de Dados', 'Inglês Técnico'],
          ['21:30  - 22:40', 'Cálculo II', 'Física II', 'Estrut. Dados', 'Banco de Dados', 'Inglês Técnico'],
        ],
        '3º': [
          ['19:00 - 21:00', 'POO', 'Probabilidade', 'Redes I', 'Banco de Dados II', 'Gestão Ágil'],
          ['21:30 - 22:40', 'POO', 'Probabilidade', 'Redes I', 'Banco de Dados II', 'Gestão Ágil'],
        ],
        '4º': [
          ['19:00 - 21:00', 'Compiladores', 'Redes II', 'Engenharia Software', 'Sistemas Operacionais', 'Empreendedorismo'],
          ['21:30 - 22:40', 'Compiladores', 'Redes II', 'Engenharia Software', 'Sistemas Operacionais', 'Empreendedorismo'],
        ],
        '5º': [
          ['19:00 - 21:00', 'IA', 'TCC', 'Segurança', 'Computação Gráfica', 'Optativa'],
          ['21:30 - 22:40', 'IA', 'TCC', 'Segurança', 'Computação Gráfica', 'Optativa'],
        ],
      };
      final rows = noturno[selectedPeriod]!;
      return rows.map((schedule) {
        return DataRow(
          color: MaterialStateProperty.resolveWith<Color?>((states) => Colors.grey[50]),
          cells: [
            ...schedule.map((cell) => DataCell(Text(cell, style: const TextStyle(fontSize: 15)))),
            DataCell(Row(
              children: [
                Tooltip(
                  message: 'Ver Localização',
                  child: IconButton(
                    icon: const Icon(Icons.location_on, color: Color(0xFF3C3CC0)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade de localização em breve!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Ver Professor',
                  child: IconButton(
                    icon: const Icon(Icons.person, color: Color(0xFF3C3CC0)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade de professor em breve!')),
                      );
                    },
                  ),
                ),
              ],
            )),
          ],
        );
      }).toList();
    } else {
      final matutino = {
        '1º': [
          ['07:30 - 08:20', 'Cálculo I', 'Física I', 'Algoritmos', 'Matemática Discreta', 'Inglês Técnico'],
          ['08:20 - 09:10', 'Cálculo I', 'Física I', 'Algoritmos', 'Matemática Discreta', 'Inglês Técnico'],
          ['09:20 - 10:10', 'Álgebra Linear', 'Lab. Física', 'Algoritmos', 'Matemática Discreta', 'Inglês Técnico'],
        ],
        '2º': [
          ['07:30 - 08:20', 'Cálculo II', 'Física II', 'Estrut. Dados', 'Banco de Dados', 'Inglês Técnico'],
          ['08:20 - 09:10', 'Cálculo II', 'Física II', 'Estrut. Dados', 'Banco de Dados', 'Inglês Técnico'],
          ['09:20 - 10:10', 'Álgebra Linear', 'Lab. Física', 'Estrut. Dados', 'Banco de Dados', 'Inglês Técnico'],
        ],
        '3º': [
          ['07:30 - 08:20', 'POO', 'Probabilidade', 'Redes I', 'Banco de Dados II', 'Gestão Ágil'],
          ['08:20 - 09:10', 'POO', 'Probabilidade', 'Redes I', 'Banco de Dados II', 'Gestão Ágil'],
          ['09:20 - 10:10', 'Compiladores', 'Redes II', 'Engenharia Software', 'Sistemas Operacionais', 'Empreendedorismo'],
        ],
        '4º': [
          ['07:30 - 08:20', 'Compiladores', 'Redes II', 'Engenharia Software', 'Sistemas Operacionais', 'Empreendedorismo'],
          ['08:20 - 09:10', 'Compiladores', 'Redes II', 'Engenharia Software', 'Sistemas Operacionais', 'Empreendedorismo'],
          ['09:20 - 10:10', 'IA', 'TCC', 'Segurança', 'Computação Gráfica', 'Optativa'],
        ],
        '5º': [
          ['07:30 - 08:20', 'IA', 'TCC', 'Segurança', 'Computação Gráfica', 'Optativa'],
          ['08:20 - 09:10', 'IA', 'TCC', 'Segurança', 'Computação Gráfica', 'Optativa'],
          ['09:20 - 10:10', 'IA', 'TCC', 'Segurança', 'Computação Gráfica', 'Optativa'],
        ],
      };
      final rows = matutino[selectedPeriod]!;
      return List.generate(rows.length, (rowIdx) {
        final schedule = rows[rowIdx];
        final isEven = rowIdx % 2 == 0;
        return DataRow(
          color: MaterialStateProperty.resolveWith<Color?>((states) => isEven ? Colors.grey[50] : Colors.white),
          cells: [
            ...schedule.map((cell) => DataCell(Text(cell, style: const TextStyle(fontSize: 15)))),
            DataCell(Row(
              children: [
                Tooltip(
                  message: 'Ver Localização',
                  child: IconButton(
                    icon: const Icon(Icons.location_on, color: Color(0xFF3C3CC0)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade de localização em breve!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Ver Professor',
                  child: IconButton(
                    icon: const Icon(Icons.person, color: Color(0xFF3C3CC0)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade de professor em breve!')),
                      );
                    },
                  ),
                ),
              ],
            )),
          ],
        );
      });
    }
  }
}
