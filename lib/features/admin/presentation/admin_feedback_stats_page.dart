import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/services/feedback_service.dart';

class AdminFeedbackStatsPage extends StatefulWidget {
  const AdminFeedbackStatsPage({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackStatsPage> createState() => _AdminFeedbackStatsPageState();
}

class _AdminFeedbackStatsPageState extends State<AdminFeedbackStatsPage> {
  final FeedbackService _feedbackService = FeedbackService();
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _feedbackService.getStatistics();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar estatísticas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const appBlue = Color(0xFF3C3CC0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appBlue,
        foregroundColor: Colors.white,
        title: const Text('Estatísticas de Feedback'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card: Total de Feedbacks
                        _buildSummaryCards(),
                        const SizedBox(height: 24),

                        // Gráfico: Distribuição por Vínculo
                        _buildVinculoChart(),
                        const SizedBox(height: 24),

                        // Gráfico: Anônimos vs Identificados
                        _buildAnonymousChart(),
                        const SizedBox(height: 24),

                        // NPS Score
                        _buildNPSCard(),
                        const SizedBox(height: 24),

                        // Médias das Avaliações
                        _buildAverageScoresCard(),
                        const SizedBox(height: 24),

                        // Botão: Exportar CSV
                        _buildExportButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _stats!['totalFeedbacks'] ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.feedback, size: 48, color: Color(0xFF3C3CC0)),
            const SizedBox(height: 12),
            Text(
              '$total',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF3C3CC0)),
            ),
            const Text('Feedbacks Recebidos', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildVinculoChart() {
    final byVinculo = _stats!['byVinculo'] as Map<String, dynamic>;
    final aluno = (byVinculo['aluno'] ?? 0).toDouble();
    final visitante = (byVinculo['visitante'] ?? 0).toDouble();
    final funcionario = (byVinculo['funcionario'] ?? 0).toDouble();
    final total = aluno + visitante + funcionario;

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Sem dados de vínculo'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuição por Vínculo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: aluno,
                      title: '${((aluno / total) * 100).toStringAsFixed(1)}%',
                      color: const Color(0xFF3C3CC0),
                      radius: 80,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: visitante,
                      title: '${((visitante / total) * 100).toStringAsFixed(1)}%',
                      color: Colors.orange,
                      radius: 80,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: funcionario,
                      title: '${((funcionario / total) * 100).toStringAsFixed(1)}%',
                      color: Colors.green,
                      radius: 80,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegendItem('Alunos', const Color(0xFF3C3CC0), aluno.toInt()),
            _buildLegendItem('Visitantes', Colors.orange, visitante.toInt()),
            _buildLegendItem('Funcionários', Colors.green, funcionario.toInt()),
          ],
        ),
      ),
    );
  }

  Widget _buildAnonymousChart() {
    final byAnonymous = _stats!['byAnonymous'] as Map<String, dynamic>;
    final anonymous = (byAnonymous['anonymous'] ?? 0).toDouble();
    final identified = (byAnonymous['identified'] ?? 0).toDouble();
    final total = anonymous + identified;

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Sem dados de identificação'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Resposta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: anonymous,
                      title: '${((anonymous / total) * 100).toStringAsFixed(1)}%',
                      color: Colors.grey,
                      radius: 80,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: identified,
                      title: '${((identified / total) * 100).toStringAsFixed(1)}%',
                      color: const Color(0xFF3C3CC0),
                      radius: 80,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegendItem('Anônimos', Colors.grey, anonymous.toInt()),
            _buildLegendItem('Identificados', const Color(0xFF3C3CC0), identified.toInt()),
          ],
        ),
      ),
    );
  }

  Widget _buildNPSCard() {
    final nps = (_stats!['nps'] ?? 0.0).toDouble();
    final npsInt = nps.round();

    Color npsColor;
    String npsLabel;

    if (nps >= 75) {
      npsColor = Colors.green;
      npsLabel = 'Excelente';
    } else if (nps >= 50) {
      npsColor = Colors.lightGreen;
      npsLabel = 'Muito Bom';
    } else if (nps >= 0) {
      npsColor = Colors.orange;
      npsLabel = 'Bom';
    } else {
      npsColor = Colors.red;
      npsLabel = 'Ruim';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Net Promoter Score (NPS)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '$npsInt',
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: npsColor),
            ),
            Text(
              npsLabel,
              style: TextStyle(fontSize: 20, color: npsColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Baseado na pergunta "Recomendaria o app?"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageScoresCard() {
    final averageScores = _stats!['averageScores'] as Map<String, dynamic>;

    final scores = {
      'Identificar Localização': averageScores['identificarLocalizacao'],
      'Instruções Claras': averageScores['instrucoesClaras'],
      'Representação Fiel': averageScores['representacaoFiel'],
      'Trajeto Fácil': averageScores['trajetoFacilSeguir'],
      'Facilidade de Uso': averageScores['facilUsar'],
      'Design Claro': averageScores['designClaro'],
      'Interação': averageScores['interacaoSemDificuldade'],
      'Tempo Razoável': averageScores['tempoRazoavel'],
      'Confiança': averageScores['confiancaDestino'],
      'Recomendaria': averageScores['recomendaria'],
      'Voltaria a Usar': averageScores['voltariaUsar'],
      'Satisfação Geral': averageScores['satisfacaoGeral'],
    };

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Médias das Avaliações (1-5)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...scores.entries.map((entry) => _buildScoreBar(entry.key, entry.value ?? 0.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score) {
    final percentage = (score / 5.0);
    Color color;

    if (score >= 4.5) {
      color = Colors.green;
    } else if (score >= 3.5) {
      color = Colors.lightGreen;
    } else if (score >= 2.5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
              Text(
                score.toStringAsFixed(2),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('$label: $count'),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          // TODO: Implementar download do CSV
          Get.snackbar(
            'Download',
            'Funcionalidade de download CSV em desenvolvimento',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          Get.snackbar(
            'Erro',
            'Erro ao exportar dados',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3C3CC0),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.download),
      label: const Text('Exportar Dados (CSV)'),
    );
  }
}
