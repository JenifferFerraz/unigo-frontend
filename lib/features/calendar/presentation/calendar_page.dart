import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/exam_service.dart';
import '../../home/presentation/components/sidebar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final ExamService _examService = ExamService();
  Map<int, List<Map<String, dynamic>>> _eventsByDay = {};
  int _selectedDay = DateTime.now().day;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final exams = await _examService.getExams(month: _currentMonth, year: _currentYear);
      final Map<int, List<Map<String, dynamic>>> map = {};
      for (final e in exams) {
        final dateStr = e['date'] as String? ?? '';
        final parts = dateStr.split('/');
        if (parts.length < 3) continue;
        final day = int.tryParse(parts[0].padLeft(2, '0'));
        final month = int.tryParse(parts[1].padLeft(2, '0'));
        final year = int.tryParse(parts[2]);
        if (day == null || month == null || year == null) continue;
        if (month == _currentMonth && year == _currentYear) {
          map.putIfAbsent(day, () => []).add(e);
        }
      }
      setState(() {
        _eventsByDay = map;
      });
    } catch (err) {}
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _eventsByDay[_selectedDay] ?? [];
    final monthNames = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        title: const Text('Calendário Acadêmico'),
        backgroundColor: const Color(0xFF3C3CC0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.emoji_events, color: Colors.white, size: 32),
          ),
        ],
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
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Calendário Acadêmico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF3C3CC0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3C3CC0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: Color(0xFF3C3CC0)),
                            onPressed: () {
                              setState(() {
                                if (_currentMonth == 1) {
                                  _currentMonth = 12;
                                  _currentYear--;
                                } else {
                                  _currentMonth--;
                                }
                                _selectedDay = 1;
                              });
                              _loadExams();
                            },
                          ),
                          Text(
                            '${monthNames[_currentMonth]} $_currentYear',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: Color(0xFF3C3CC0)),
                            onPressed: () {
                              setState(() {
                                if (_currentMonth == 12) {
                                  _currentMonth = 1;
                                  _currentYear++;
                                } else {
                                  _currentMonth++;
                                }
                                _selectedDay = 1;
                              });
                              _loadExams();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Dom'), Text('Seg'), Text('Ter'), Text('Qua'), Text('Qui'), Text('Sex'), Text('Sáb'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: DateUtils.getDaysInMonth(_currentYear, _currentMonth),
                        itemBuilder: (context, i) {
                          final day = i + 1;
                          final hasEvent = _eventsByDay.containsKey(day);
                          final isSelected = day == _selectedDay;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDay = day;
                                _expanded = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF3C3CC0) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$day',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (hasEvent)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Color(0xFF3C3CC0),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Selected day events
                Text(
                  'Provas em $_selectedDay/${_currentMonth.toString().padLeft(2, '0')}/${_currentYear}',
                  style: TextStyle(color: Color(0xFF3C3CC0), fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (selectedEvents.isEmpty)
                  const Text('Não há provas programadas para esta data.'),
                if (selectedEvents.isNotEmpty) ...[
                  for (int i = 0; i < selectedEvents.length && (i < 3 || _expanded); i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedEvents[i]['subject'] ?? '', style: const TextStyle(fontSize: 15)),
                              Text(selectedEvents[i]['time'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                          Text(selectedEvents[i]['grade'] ?? '', style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  if (selectedEvents.length > 3 && !_expanded)
                    TextButton(
                      onPressed: () => setState(() => _expanded = true),
                      child: Text('Mostrar mais (${selectedEvents.length - 3})'),
                    ),
                  if (_expanded)
                    TextButton(
                      onPressed: () => setState(() => _expanded = false),
                      child: const Text('Mostrar menos'),
                    ),
                ],

                const SizedBox(height: 8),
                Center(
                  child: Icon(Icons.keyboard_arrow_down, color: Color(0xFF3C3CC0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
