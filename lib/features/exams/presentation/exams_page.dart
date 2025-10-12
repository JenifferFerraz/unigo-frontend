import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/exam_service.dart';
import '../../home/presentation/components/sidebar.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({Key? key}) : super(key: key);

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  final ExamService _examService = ExamService();
  int _selectedCycle = 0; 
  List<int> _availableCycles = [];

  @override
  void initState() {
    super.initState();
    _discoverCycles();
  }
  String _selectedShift = 'all'; // 'all' | 'matutino' | 'noturno'

  Future<void> _discoverCycles() async {
    try {
      final all = await _examService.getExams();
      final set = <int>{};
      for (final e in all) {
        final c = e['cycle'];
        if (c is int) set.add(c);
        if (c is String) {
          final parsed = int.tryParse(c);
          if (parsed != null) set.add(parsed);
        }
      }
      final list = set.toList()..sort();
      setState(() {
        _availableCycles = list;
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadExams() {
    final int? cycle = _selectedCycle == 0 ? null : _selectedCycle;
    final shift = _selectedShift == 'all' ? null : _selectedShift;
    return _examService.getExams(cycle: cycle, shift: shift);
  }

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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('$_selectedCycle-$_selectedShift'),
            future: _loadExams(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro ao carregar provas: \$${snapshot.error}'));
              }

              final exams = snapshot.data ?? [];

              if (exams.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('Nenhuma prova encontrada para o filtro selecionado')),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cycle selector as a dropdown (matches previous layout)
                    DropdownButtonFormField<int>(
                      value: _selectedCycle,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Todos')),
                        ..._availableCycles.map((c) => DropdownMenuItem(value: c, child: Text('Ciclo ${c.toString().padLeft(2, '0')}'))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedCycle = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Shift selector: Matutino / Noturno
                    DropdownButtonFormField<String>(
                      value: _selectedShift,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todos horários')),
                        DropdownMenuItem(value: 'matutino', child: Text('Matutino')),
                        DropdownMenuItem(value: 'noturno', child: Text('Noturno')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedShift = v;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Aplicação de Provas 1ª VA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    // Group exams by date so the day header appears once per date
                    ..._buildGroupedExamWidgets(exams),
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
              );
            },
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
          // Header: day on left, date on right to avoid long combined text
          Row(
            children: [
              Expanded(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 140),
                child: Text(date, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildExamItem(String subject, String time, String grade) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: subject + time, take remaining space and ellipsize if long
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: compact grade/period area with fixed width to avoid overflow
          SizedBox(
            width: 60,
            child: Text(
              grade,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedExamWidgets(List<Map<String, dynamic>> exams) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final e in exams) {
      final date = e['date'] ?? 'Sem data';
      grouped.putIfAbsent(date, () => []).add(e);
    }

    final List<String> sortedDates = grouped.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final widgets = <Widget>[];
    for (final date in sortedDates) {
      final list = grouped[date]!;
      // use day name from first element if available
      final dayName = list.first['day'] ?? '';
      widgets.add(_buildExamDay(dayName, date, [
        for (final e in list) _buildExamItem(e['subject'] ?? '', e['time'] ?? '', e['grade'] ?? ''),
      ]));
    }
    return widgets;
  }
}
