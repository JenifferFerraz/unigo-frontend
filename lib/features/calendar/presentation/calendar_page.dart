import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/calendar_service.dart';
import '../../../storage/token_storage.dart';
import '../../../data/services/auth_service.dart';
import '../../home/presentation/components/sidebar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final CalendarService _calendarService;
  Map<int, List<Map<String, dynamic>>> _eventsByDay = {};
  int _selectedDay = DateTime.now().day;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  bool _expanded = false;
  String? _selectedCourse;
  List<Map<String, dynamic>> _coursesData = [];
  bool _isLoading = false;
  
  bool get _isAdmin {
    final user = Get.find<AuthService>().currentUser.value;
    return user != null && user.role == 'admin';
  }

  @override
  void initState() {
    super.initState();
    _calendarService = CalendarService();
    if (_isAdmin) {
      _fetchCoursesForAdmin();
    }
    _setUserCourseAndLoad();
  }

  Future<void> _fetchCoursesForAdmin() async {
    final courses = await _calendarService.fetchCourses();
    setState(() {
      _coursesData = courses;
      if (_coursesData.isNotEmpty && _selectedCourse == null) {
        _selectedCourse = _coursesData[0]['id'].toString();
      }
    });
  }

  Future<void> _setUserCourseAndLoad() async {
    final user = Get.find<AuthService>().currentUser.value;
    if (user != null && !_isAdmin) {
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
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final user = Get.find<AuthService>().currentUser.value;
      String? courseIdToSend;
      if (_isAdmin) {
        courseIdToSend = _selectedCourse;
      } else {
        courseIdToSend = _selectedCourse;
      }
      final events = await _calendarService.getCalendarEvents(
        month: _currentMonth,
        year: _currentYear,
        courseId: courseIdToSend,
        isActive: true,
        role: user?.role,
      );
      
      final Map<int, List<Map<String, dynamic>>> map = {};
      
      for (final event in events) {
        final dateStr = event['date'] as String? ?? '';
        List<String> parts;
        if (dateStr.contains('/')) {
          parts = dateStr.split('/'); 
        } else if (dateStr.contains('-')) {
          parts = dateStr.split('-'); 
          if (parts.length == 3) {
            parts = [parts[2], parts[1], parts[0]];
          }
        } else {
          parts = [];
        }
        if (parts.length < 3) continue;
        final day = int.tryParse(parts[0].padLeft(2, '0'));
        final month = int.tryParse(parts[1].padLeft(2, '0'));
        final year = int.tryParse(parts[2]);
        if (day == null || month == null || year == null) continue;
        if (month == _currentMonth && year == _currentYear) {
          map.putIfAbsent(day, () => []).add(event);
        }
      }
      
      setState(() {
        _eventsByDay = map;
        _isLoading = false;
      });
    } catch (err) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar eventos: ${err.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth += delta;
      
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
      
      _selectedDay = 1;
    });
    
    _loadEvents();
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
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00d9ff), Color(0xFF3C3CC0)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00d9ff).withOpacity(0.5),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.emoji_events, color: Colors.white, size: 32),
              padding: EdgeInsets.all(6),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF00d9ff),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00d9ff).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(Icons.notifications, color: Colors.white, size: 28),
              padding: EdgeInsets.all(6),
            ),
          ),
        ],
      ),
      drawer: Sidebar(),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          width: MediaQuery.of(context).size.width < 520 
              ? MediaQuery.of(context).size.width - 16 
              : 500,
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF3C3CC0)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isAdmin && _coursesData.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DropdownButton<String>(
                            value: _selectedCourse,
                            hint: Text('Filtrar por curso'),
                            isExpanded: true,
                            items: _coursesData.map((course) {
                              return DropdownMenuItem(
                                value: course['id'].toString(),
                                child: Text(course['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCourse = value;
                              });
                              _loadEvents();
                            },
                          ),
                        ),
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
                                  onPressed: () => _changeMonth(-1),
                                ),
                                Text(
                                  '${monthNames[_currentMonth]} $_currentYear',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  icon: Icon(Icons.chevron_right, color: Color(0xFF3C3CC0)),
                                  onPressed: () => _changeMonth(1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Dom'), Text('Seg'), Text('Ter'), Text('Qua'), 
                                Text('Qui'), Text('Sex'), Text('Sáb'),
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

                      Text(
                        'Eventos em $_selectedDay/${_currentMonth.toString().padLeft(2, '0')}/$_currentYear',
                        style: TextStyle(
                          color: Color(0xFF3C3CC0), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 15
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedEvents.isEmpty)
                        const Text('Não há eventos programados para esta data.'),
                      if (selectedEvents.isNotEmpty) ...[
                        for (int i = 0; i < selectedEvents.length && (i < 3 || _expanded); i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF3C3CC0).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFF3C3CC0).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedEvents[i]['title'] ?? selectedEvents[i]['subject'] ?? 'Evento',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (selectedEvents[i]['description'] != null && selectedEvents[i]['description'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              selectedEvents[i]['description'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        if (selectedEvents[i]['type'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              selectedEvents[i]['type'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF3C3CC0),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (selectedEvents[i]['grade'] != null)
                                    Text(
                                      selectedEvents[i]['grade'] ?? '',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (selectedEvents.length > 3)
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _expanded = !_expanded),
                              icon: Icon(
                                _expanded ? Icons.expand_less : Icons.expand_more,
                                color: Color(0xFF3C3CC0),
                              ),
                              label: Text(
                                _expanded
                                    ? 'Mostrar menos'
                                    : 'Mostrar mais (${selectedEvents.length - 3})',
                                style: TextStyle(
                                  color: Color(0xFF3C3CC0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}