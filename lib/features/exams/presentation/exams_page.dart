import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/exam_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../storage/token_storage.dart';
import '../../home/presentation/components/sidebar.dart';
import '../../events/data/event_api_service.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({Key? key}) : super(key: key);

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  final ExamService _examService = ExamService();
  int _selectedCycle = 0; 
  List<int> _availableCycles = [];
  String _selectedShift = 'all';
  
  List<Map<String, dynamic>> _coursesData = [];
  String? _selectedCourse;
  bool _isLoading = false;

  bool get _isAdmin {
    final user = Get.find<AuthService>().currentUser.value;
    return user != null && user.role == 'admin';
  }

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (_isAdmin) {
      await _fetchCoursesForAdmin();
    } else {
      await _setUserCourseAndLoad();
    }
  }

  Future<void> _fetchCoursesForAdmin() async {
    final service = EventApiService();
    try {
      final courses = await service.fetchCourses();
      setState(() {
        _coursesData = courses;
        if (_coursesData.isNotEmpty) {
          _selectedCourse = _coursesData[0]['id'].toString();
        }
      });
      if (_selectedCourse != null) {
        await _discoverCycles();
      }
    } catch (e) {
      print('Erro ao buscar cursos: $e');
    }
  }

  Future<void> _setUserCourseAndLoad() async {
    final user = Get.find<AuthService>().currentUser.value;
    if (user != null) {
      _selectedCourse = user.courseId?.toString();
      if (_selectedCourse == null || _selectedCourse!.isEmpty) {
        try {
          final courseId = await TokenStorage.getCourseId();
          if (courseId != null && courseId.isNotEmpty) {
            _selectedCourse = courseId;
          } else {
            if (mounted) {
              Get.offAllNamed('/login');
              return;
            }
          }
        } catch (_) {
          if (mounted) {
            Get.offAllNamed('/login');
            return;
          }
        }
      }
    }
    await _discoverCycles();
  }

  Future<void> _discoverCycles() async {
    if (_selectedCourse == null) return;
    
    try {
      final all = await _examService.getExams(courseId: _selectedCourse);
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
    } catch (e) {
      print('Erro ao descobrir ciclos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadExams() {
    if (_selectedCourse == null) return Future.value([]);
    
    final int? cycle = _selectedCycle == 0 ? null : _selectedCycle;
    final String? shift = (_selectedShift == 'all' || _selectedShift.isEmpty) ? null : _selectedShift;
    return _examService.getExams(
      cycle: cycle, 
      shift: shift, 
      courseId: _selectedCourse,
    );
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
            key: ValueKey('$_selectedCycle-$_selectedShift-$_selectedCourse'),
            future: _loadExams(),
            builder: (context, snapshot) {
              final exams = snapshot.data ?? [];
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isAdmin) ...[
                      if (_coursesData.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedCourse,
                          decoration: const InputDecoration(
                            labelText: 'Curso',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixIcon: Icon(Icons.school, color: Color(0xFF3C3CC0)),
                          ),
                          items: _coursesData.map((course) {
                            return DropdownMenuItem<String>(
                              value: course['id'].toString(),
                              child: Text(
                                course['name'] ?? 'Sem nome',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedCourse = v;
                              _selectedCycle = 0;
                              _availableCycles = [];
                            });
                            _discoverCycles();
                          },
                        ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<int>(
                      value: _selectedCycle,
                      decoration: const InputDecoration(
                        labelText: 'Ciclo',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF3C3CC0)),
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
                    DropdownButtonFormField<String>(
                      value: _selectedShift,
                      decoration: const InputDecoration(
                        labelText: 'Turno',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(Icons.access_time, color: Color(0xFF3C3CC0)),
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
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                    if (snapshot.hasError)
                      Center(child: Text('Erro ao carregar provas: ${snapshot.error}')),
                    if (!snapshot.hasError && snapshot.connectionState == ConnectionState.done && exams.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(child: Text('Nenhuma prova encontrada para o filtro selecionado')),
                      ),
                    if (exams.isNotEmpty)
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
    String formattedDate = date;
    try {
      if (date.contains('-') && date.split('-').length == 3) {
        final parts = date.split('-');
        if (parts[0].length == 4) {
          // Formato yyyy-MM-dd, converter para dd/MM/yyyy
          formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
    } catch (_) {
      // Se falhar, usa a data original
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 140),
                child: Text(formattedDate, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      final dayName = list.first['day'] ?? '';
      widgets.add(_buildExamDay(dayName, date, [
        for (final e in list) _buildExamItem(e['subject'] ?? '', e['time'] ?? '', e['grade'] ?? ''),
      ]));
    }
    return widgets;
  }
}
