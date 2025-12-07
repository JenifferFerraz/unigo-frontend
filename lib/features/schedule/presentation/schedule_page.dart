import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../routes/app_routes.dart';
import '../../home/presentation/components/sidebar.dart';
import '../../../../core/config/env_service.dart';
import '../../../../data/services/storage_service.dart';

class SchedulePage extends StatefulWidget {
  final AuthService _authService = Get.find<AuthService>();

  SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePage();
}

class _SchedulePage extends State<SchedulePage> {
  List<dynamic> scheduleList = [];
  bool isLoading = true;
  String selectedPeriod = 'Todos';
  List<String> periods = [];
  int totalPeriods = 0;
  final GetConnect _getConnect = GetConnect();

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    final user = widget._authService.currentUser.value;

    if (user == null || user.courseId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    final url = '${EnvService.apiBaseUrl}/schedules?courseId=${user.courseId}';
    String? token;
    
    if (Get.isRegistered<AuthService>()) {
      final authService = Get.find<AuthService>();
      final userData = await authService.storage.getUserData();
      token = userData?['token'];
    }
    
    if (token == null && Get.isRegistered<StorageService>()) {
      final storageService = Get.find<StorageService>();
      token = await storageService.getToken();
    }
    
    final response = await _getConnect.get(
      url,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    if (response.statusCode != 200) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    dynamic responseData = response.body ?? {};
    List<dynamic> schedules = [];
    int periodsCount = 0;
    
    if (responseData is Map) {
      dynamic schedulesRaw = responseData['schedules'];
      if (schedulesRaw is List) {
        schedules = schedulesRaw;
      } else if (schedulesRaw is String) {
        try {
          schedules = schedulesRaw.isNotEmpty 
              ? List<dynamic>.from(jsonDecode(schedulesRaw)) 
              : [];
        } catch (_) {
          schedules = [];
        }
      } else {
        schedules = [];
      }
      
      dynamic periodsRaw = responseData['periods'];
      if (periodsRaw is int) {
        periodsCount = periodsRaw;
      } else if (periodsRaw is String) {
        periodsCount = int.tryParse(periodsRaw) ?? 0;
      } else {
        periodsCount = int.tryParse(periodsRaw?.toString() ?? '') ?? 0;
      }
    } else if (responseData is List) {
      schedules = responseData;
    }
    
    List<String> generatedPeriods = [];
    if (periodsCount > 0) {
      generatedPeriods = List.generate(periodsCount, (i) => '${i + 1}º');
    }
    generatedPeriods.insert(0, 'Todos');
    
    setState(() {
      scheduleList = schedules;
      periods = generatedPeriods;
      totalPeriods = periodsCount;
      selectedPeriod = 'Todos';
      isLoading = false;
    });
  }

  Widget _buildDaySection(String day, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day, 
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
            ),
          ),
          ...items.map((item) {
            final subject = item['subject'] ?? '';
            final room = item['room'] ?? '';
            String timeRaw = item['time'] ?? '';
            String timeFormatted = timeRaw;
            
            final timeParts = timeRaw.split(':');
            if (timeParts.length >= 1 && timeParts[0].isNotEmpty) {
              timeFormatted = timeParts[0] + 'h';
            }
            
            final semester = item['semester'] != null 
                ? '${item['semester']}º período' 
                : '';
            
            return _buildScheduleItem(
              '$subject ($semester)', 
              room, 
              timeFormatted, 
              structureId: item['structureId'],
              roomId: item['roomId'],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    String subject, 
    String location, 
    String time, 
    {int? structureId, int? roomId}
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C3CC0),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      location, 
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (structureId != null && structureId > 0 && roomId != null)
                          ? const Color(0xFF3C3CC0)
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Ir para sala'),
                    onPressed: (structureId != null && structureId > 0 && roomId != null)
                        ? () {
                            print('[SchedulePage] Botão Ir para sala clicado: location=$location, roomId=$roomId, structureId=$structureId');
                            Get.toNamed(
                              AppRoutes.HOME,
                              arguments: {
                                'roomId': roomId,
                                'structureId': structureId,
                              },
                            );
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3CC0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Navega para a sala com busca e navegação automáticas
  Future<void> _navigateToRoom(String roomName) async {
    if (roomName.isEmpty) return;

    print('[SchedulePage] Navegando para sala: $roomName');

    // Navega para LocationSearchPreFiltered com query e autoNavigate
    Get.toNamed(
      AppRoutes.LOCATION_SEARCH,
      arguments: {
        'query': roomName,
        'autoNavigate': true,
      },
    );
  }

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
          return const Center(
            child: Text(
              'Usuário não encontrado',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        
        final days = [
          'SEGUNDA-FEIRA',
          'TERÇA-FEIRA',
          'QUARTA-FEIRA',
          'QUINTA-FEIRA',
          'SEXTA-FEIRA',
          'SÁBADO'
        ];
        
        final Map<String, List<dynamic>> scheduleByDay = {
          for (var d in days) d: []
        };
        
        List<dynamic> filteredList;
        if (selectedPeriod == 'Todos') {
          filteredList = scheduleList;
        } else {
          final selectedSemester = int.tryParse(selectedPeriod[0]) ?? 1;
          filteredList = scheduleList
              .where((item) => item['semester'] == selectedSemester)
              .toList();
        }
        
        for (var item in filteredList) {
          final day = item['dayOfWeek']?.toUpperCase() ?? '';
          if (scheduleByDay.containsKey(day)) {
            scheduleByDay[day]!.add(item);
          }
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Selecione o período:', 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: selectedPeriod,
                      items: periods.map((period) {
                        return DropdownMenuItem<String>(
                          value: period,
                          child: Text(period),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPeriod = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: scheduleList.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum horário encontrado para seu curso.',
                          ),
                        )
                      : filteredList.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum horário cadastrado para este período.',
                              ),
                            )
                          : ListView(
                              children: days
                                  .map((day) => _buildDaySection(
                                        day, 
                                        scheduleByDay[day]!,
                                      ))
                                  .toList(),
                            ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Observações',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '• Os horários podem sofrer alterações', 
                  style: TextStyle(fontSize: 15),
                ),
                const Text(
                  '• Em caso de dúvidas, consulte a coordenação', 
                  style: TextStyle(fontSize: 15),
                ),
                const Text(
                  '• Fique atento aos feriados e recessos', 
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}