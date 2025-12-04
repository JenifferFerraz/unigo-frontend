import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../storage/token_storage.dart';
import '../../home/presentation/components/sidebar.dart';
import '../data/event_api_service.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<Event>> _eventsFuture;
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
    if (_isAdmin) {
      _fetchCoursesForAdmin();
    }
    _setUserCourseAndLoad();
  }

  Future<void> _fetchCoursesForAdmin() async {
    final service = EventApiService();
    try {
      final courses = await service.fetchCourses();
      setState(() {
        _coursesData = courses;
        if (_coursesData.isNotEmpty && _selectedCourse == null) {
          _selectedCourse = _coursesData[0]['id'].toString();
        }
      });
    } catch (_) {}
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
      final service = EventApiService();
      final events = await service.fetchEvents(courseId: _selectedCourse);
      setState(() {
        _eventsFuture = Future.value(events);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      drawer: Sidebar(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset(
              'assets/images/Logo.png',
              height: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Eventos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            if (_isAdmin && _coursesData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButton<String>(
                  value: _selectedCourse,
                  hint: const Text('Filtrar por curso'),
                  isExpanded: true,
                  items: _coursesData.map((course) {
                    return DropdownMenuItem(
                      value: course['id'].toString(),
                      child: Text(course['name'] ?? course['nome'] ?? ''),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<List<Event>>(
                      future: _eventsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Erro ao carregar eventos'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('Nenhum evento encontrado'));
                        }
                        final events = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            final isEsports = _isEsportsEvent(event);
                            return isEsports
                                ? EsportsEventCard(event: event)
                                : EventCard(event: event);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isEsportsEvent(Event event) {
    final keywords = ['e-sport', 'esport', 'gaming', 'torneio', 'campeonato'];
    final searchText = '${event.title} ${event.location}'.toLowerCase();
    return keywords.any((keyword) => searchText.contains(keyword));
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  String _formatDateRange() {
    try {
      final start = DateTime.parse(event.startDate ?? '');
      final end = event.endDate != null ? DateTime.parse(event.endDate!) : null;
      
      final formatter = DateFormat('dd/MM/yyyy');
      
      if (end != null && start != end) {
        return '${formatter.format(start)} - ${formatter.format(end)}';
      } else {
        return formatter.format(start);
      }
    } catch (e) {
      return event.startDate ?? 'Data não disponível';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3C3CC0), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C3CC0),
              ),
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(Icons.place, 'Local: ${event.location}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Data: ${_formatDateRange()}'),
            const SizedBox(height: 16),
            if (event.link != null && event.link!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _launchUrl(event.link!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C3CC0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Inscreva-se',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF3C3CC0),
        colorText: Colors.white,
      );
    }
  }
}

class EsportsEventCard extends StatelessWidget {
  final Event event;

  const EsportsEventCard({Key? key, required this.event}) : super(key: key);

  String _formatDateRange() {
    try {
      final start = DateTime.parse(event.startDate ?? '');
      final end = event.endDate != null ? DateTime.parse(event.endDate!) : null;
      
      final formatter = DateFormat('dd/MM/yyyy');
      
      if (end != null && start != end) {
        return '${formatter.format(start)} - ${formatter.format(end)}';
      } else {
        return formatter.format(start);
      }
    } catch (e) {
      return event.startDate ?? 'Data não disponível';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00d9ff).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00d9ff), Color(0xFF00b4d8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00d9ff).withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'E-SPORTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00d9ff),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00d9ff).withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00d9ff),
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Color(0xFF00d9ff),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                _buildEsportsInfoRow(Icons.place, event.location),
                const SizedBox(height: 12),
                _buildEsportsInfoRow(Icons.calendar_today, _formatDateRange()),
                const SizedBox(height: 20),
                if (event.link != null && event.link!.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00d9ff), Color(0xFF00b4d8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00d9ff).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _launchUrl(event.link!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_esports, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'INSCREVA-SE AGORA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsportsInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00d9ff).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00d9ff).withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF00d9ff),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00d9ff).withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}