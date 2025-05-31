import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../../../data/models/location_model.dart';
import 'location_detail_page.dart';
import 'package:intl/intl.dart';

class ClassNotificationsPage extends StatelessWidget {
  final LocationController controller = Get.find<LocationController>();

  ClassNotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Aulas'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadUpcomingClasses(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.error.value),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.loadUpcomingClasses,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (controller.upcomingClasses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma aula agendada para hoje',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aproveite seu tempo livre!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.upcomingClasses.length,
            itemBuilder: (context, index) {
              final classNotification = controller.upcomingClasses[index];
              return _buildClassCard(context, classNotification);
            },
          );
        }),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, ClassNotification classNotification) {
    // Formata os horários de início e fim
    final startTime = _formatTime(classNotification.startTime);
    final endTime = _formatTime(classNotification.endTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do curso e turma
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.school, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classNotification.courseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Turma: ${classNotification.className}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Informações da localização e horário
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${classNotification.locationName} (${classNotification.locationCode})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.business, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Bloco ${classNotification.block}' +
                                (classNotification.floor != null
                                    ? ' • Piso ${classNotification.floor}'
                                    : ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$startTime - $endTime',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Simulação - Criar Location a partir do ClassNotification
                    final location = Location(
                      id: 0, // ID não importa neste caso
                      name: classNotification.locationName,
                      code: classNotification.locationCode,
                      type: 'classroom', // Tipo padrão para aulas
                      block: classNotification.block,
                      floor: classNotification.floor,
                    );
                    Get.to(() => LocationDetailPage(location: location));
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Ver Local'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Aqui irá integrar com a navegação interna do campus
                    Get.snackbar(
                      'Navegar',
                      'Navegação interna será implementada em breve',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Navegar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Formata o tempo de "HH:MM:SS" para "HH:MM"
  String _formatTime(String timeString) {
    try {
      final time = DateFormat('HH:mm:ss').parse(timeString);
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      // Se houver erro, retornar o string original
      return timeString;
    }
  }
}
