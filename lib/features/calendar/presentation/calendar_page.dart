import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/presentation/components/sidebar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedDay = 9; // Exemplo: dia 9 destacado
    final events = [
      {
        'date': '03/10',
        'title': 'Último prazo para lançamento das notas de 1ª VA no Lyceum',
      },
      {
        'date': '10/10',
        'title': 'Último prazo para lançamento da frequência de setembro no Lyceum',
      },
      {
        'date': '12/10',
        'title': 'Feriado Nacional',
      },
      {
        'date': '15/10',
        'title': 'Dia do Professor',
      },
      {
        'date': '20 a 23/10',
        'title': 'VI Congresso Internacional de Pesquisa, Ensino e Extensão (CIPEEX)',
      },
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
            child: Icon(Icons.emoji_events, color: Colors.white, size: 32), // Substitua por logo se quiser
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
                          Icon(Icons.chevron_left, color: Color(0xFF3C3CC0)),
                          const Text('Outubro 2025', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Icon(Icons.chevron_right, color: Color(0xFF3C3CC0)),
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
                        itemCount: 31,
                        itemBuilder: (context, i) {
                          final day = i + 1;
                          final isSelected = day == selectedDay;
                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFF3C3CC0) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...events.map((event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['date']!,
                        style: TextStyle(
                          color: Color(0xFF3C3CC0),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        event['title']!,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                )),
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
