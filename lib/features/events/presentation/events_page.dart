import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/event_model.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data - substitua por dados reais da API
    final events = [
      Event(
        id: 1,
        title: 'Puzzle Week - Engenharia de Software - 2025/2',
        city: 'Anápolis / Goiás',
        location: 'UniEVANGÉLICA - Universidade Evangélica de Goiás',
        date: 'terça-feira, 05 de agosto de 2025',
      ),
      Event(
        id: 2,
        title: 'Conferência Ciência e Propósito: o Universo, a Vida e a Missão de Cristo - AIG',
        city: 'Anápolis / Goiás',
        location: 'Evento presencial em UniEVANGÉLICA - Universidade Evangélica de Goiás',
        date: '11 ago • 2025 • 08:15 > 14 ago • 2025 • 23:59',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(event: event);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({Key? key, required this.event}) : super(key: key);

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
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_city, 'Cidade: ${event.city}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.place, 'Local: ${event.location}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Data: ${event.date}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Ação de inscrição
                  Get.snackbar(
                    'Inscrição',
                    'Inscrição em ${event.title}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF3C3CC0),
                    colorText: Colors.white,
                  );
                },
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
}
