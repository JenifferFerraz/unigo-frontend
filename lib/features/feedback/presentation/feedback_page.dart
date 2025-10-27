import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/feedback_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with TickerProviderStateMixin {
  int _currentStep = 0; // 0=parte 1, 1=parte 2, 2=parte 3, 3=parte 4
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final FeedbackService _feedbackService = FeedbackService();
  bool _isSubmitting = false;
  
  String? _vinculo;
  bool? _jaUsouAppInterno;
  int? _q3;
  int? _q4;
  int? _q5;
  int? _q6;
  int? _q7;
  int? _q8;
  int? _q9;
  int? _q10;
  int? _q11;
  int? _q12;
  int? _q13;
  int? _q14;
  final TextEditingController _q15Controller = TextEditingController();
  final TextEditingController _q16Controller = TextEditingController();
  final TextEditingController _q17Controller = TextEditingController();

  String _sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
  
    final dangerousPatterns = [
      RegExp(r"('|(\\')|(;)|(\\;)|(--)|(/\*)|(\/\*)|(\*/)|(\*\/)|(xp_)|(sp_))", caseSensitive: false),
      RegExp(r'\b(DROP|DELETE|INSERT|UPDATE|SELECT|UNION|EXEC|EXECUTE|SCRIPT|JAVASCRIPT|ALERT)\b', caseSensitive: false),
    ];
    
    String sanitized = input;
    for (var pattern in dangerousPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    sanitized = sanitized.replaceAll(RegExp(r'[<>{}]'), '');
    
    return sanitized.trim();
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _q15Controller.dispose();
    _q16Controller.dispose();
    _q17Controller.dispose();
    super.dispose();
  }
  bool get _canContinueStep1 => _vinculo != null && _jaUsouAppInterno != null && _q3 != null && _q4 != null;
  bool get _canContinueStep2 => _q5 != null && _q6 != null && _q7 != null && _q8 != null && _q9 != null;
  bool get _canContinueStep3 => _q10 != null && _q11 != null && _q12 != null && _q13 != null && _q14 != null;
  bool get _canContinueStep4 => true; // respostas abertas opcionais
  bool get _canContinue =>
      _currentStep == 0
          ? _canContinueStep1
          : _currentStep == 1
              ? _canContinueStep2
              : _currentStep == 2
                  ? _canContinueStep3
                  : _canContinueStep4;

  double get _progress {
    double baseProgress = _currentStep * 0.25; // 0%, 25%, 50%, 75%
    double stepProgress = 0.0;
    
    if (_currentStep == 0) {
      // Step 1: 4 perguntas obrigatórias (2 radio + 2 likert)
      int answered = 0;
      if (_vinculo != null) answered++;
      if (_jaUsouAppInterno != null) answered++;
      if (_q3 != null) answered++;
      if (_q4 != null) answered++;
      stepProgress = answered * 0.0625; // 6.25% por resposta
    } else if (_currentStep == 1) {
      // Step 2: 5 perguntas likert
      int answered = 0;
      if (_q5 != null) answered++;
      if (_q6 != null) answered++;
      if (_q7 != null) answered++;
      if (_q8 != null) answered++;
      if (_q9 != null) answered++;
      stepProgress = answered * 0.05; // 5% por resposta (5 * 5% = 25%)
    } else if (_currentStep == 2) {
      // Step 3: 5 perguntas likert
      int answered = 0;
      if (_q10 != null) answered++;
      if (_q11 != null) answered++;
      if (_q12 != null) answered++;
      if (_q13 != null) answered++;
      if (_q14 != null) answered++;
      stepProgress = answered * 0.05; // 5% por resposta
    } else if (_currentStep == 3) {
      // Step 4: perguntas abertas (opcionais) - sempre 25% quando chegar aqui
      stepProgress = 0.25;
    }
    
    return baseProgress + stepProgress;
  }

  void _updateProgress() {
    final targetProgress = _progress;
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward(from: 0.0);
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questionTitle('1. Qual seu vínculo com a universidade?'),
                      _radioOption('Aluno da UniEVANGÉLICA', 'aluno', _vinculo, (v) => setState(() { _vinculo = v; _updateProgress(); })),
                      _radioOption('Visitante', 'visitante', _vinculo, (v) => setState(() { _vinculo = v; _updateProgress(); })),
                      _radioOption('Funcionário', 'funcionario', _vinculo, (v) => setState(() { _vinculo = v; _updateProgress(); })),
          const SizedBox(height: 10),
          _questionTitle('2. Já havia utilizado algum aplicativo de mapeamento interno antes (ex: Google Indoor Maps, Mapwize)?'),
          _radioOption('Sim', 'sim', _jaUsouAppInterno == null ? null : (_jaUsouAppInterno! ? 'sim' : 'nao'), (v) => setState(() { _jaUsouAppInterno = v == 'sim'; _updateProgress(); })),
          _radioOption('Não', 'nao', _jaUsouAppInterno == null ? null : (_jaUsouAppInterno! ? 'sim' : 'nao'), (v) => setState(() { _jaUsouAppInterno = v == 'sim'; _updateProgress(); })),
          const SizedBox(height: 10),
          _questionTitle('3. Eu consegui identificar facilmente o ponto onde eu estava no mapa.'),
          _likertRow(_q3, (v) => setState(() { _q3 = v; _updateProgress(); })),
          const SizedBox(height: 10),
          _questionTitle('4. As instruções do aplicativo foram claras para chegar ao destino.'),
          _likertRow(_q4, (v) => setState(() { _q4 = v; _updateProgress(); })),
        ],
      );
    }
    // Step 2
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle('5. A representação do campus (blocos, salas, banheiros etc.) estava fiel à realidade.'),
        _likertRow(_q5, (v) => setState(() { _q5 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('6. O trajeto indicado pelo UniGo foi fácil de seguir.'),
        _likertRow(_q6, (v) => setState(() { _q6 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('7. O aplicativo foi fácil de usar, mesmo sem instruções.'),
        _likertRow(_q7, (v) => setState(() { _q7 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('8. As cores, ícones e textos facilitaram o entendimento das informações.'),
        _likertRow(_q8, (v) => setState(() { _q8 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('9. Consegui interagir com o mapa sem dificuldades (zoom, movimento, etc.).'),
        _likertRow(_q9, (v) => setState(() { _q9 = v; _updateProgress(); })),
      ],
    );
    
    // Step 3 (unreachable fallback)
  }

  Widget _buildStepContentStep4() {
    InputDecoration _inputDecoration() => InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3C3CC0)),
          ),
          contentPadding: const EdgeInsets.all(12),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle('15. O que mais te agradou na funcionalidade de mapeamento?'),
        TextField(
          controller: _q15Controller,
          decoration: _inputDecoration(),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        _questionTitle('16. Que dificuldade você encontrou ao usar o UniGo (se houver)?'),
        TextField(
          controller: _q16Controller,
          decoration: _inputDecoration(),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        _questionTitle('17. Você acredita que essa ferramenta pode ajudar novos alunos ou visitantes? Por quê?'),
        TextField(
          controller: _q17Controller,
          decoration: _inputDecoration(),
          maxLines: 4,
        ),
      ],
    );
  }

  void _submitFeedback() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      String deviceInfo = 'Unknown';
      try {
        if (kIsWeb) {
          deviceInfo = 'Web';
        } else {
          if (Platform.isAndroid) {
            deviceInfo = 'Android';
          } else if (Platform.isIOS) {
            deviceInfo = 'iOS';
          } else if (Platform.isWindows) {
            deviceInfo = 'Windows';
          } else if (Platform.isMacOS) {
            deviceInfo = 'MacOS';
          } else if (Platform.isLinux) {
            deviceInfo = 'Linux';
          }
        }
      } catch (_) {}

      final feedbackData = {
        'vinculo': _vinculo,
        'jaUsouAppInterno': _jaUsouAppInterno,
        'identificarLocalizacao': _q3,
        'instrucoesClaras': _q4,
        'representacaoFiel': _q5,
        'trajetoFacilSeguir': _q6,
        'facilUsar': _q7,
        'designClaro': _q8,
        'interacaoSemDificuldade': _q9,
        'tempoRazoavel': _q10,
        'confiancaDestino': _q11,
        'recomendaria': _q12,
        'voltariaUsar': _q13,
        'satisfacaoGeral': _q14,
        'oQueAgradou': _q15Controller.text.isNotEmpty ? _sanitizeInput(_q15Controller.text) : null,
        'dificuldadesEncontradas': _q16Controller.text.isNotEmpty ? _sanitizeInput(_q16Controller.text) : null,
        'sugestoesMelhoria': _q17Controller.text.isNotEmpty ? _sanitizeInput(_q17Controller.text) : null,
        'deviceInfo': deviceInfo,
        'appVersion': '1.0.0',
      };

      final result = await _feedbackService.submitFeedback(feedbackData);

      if (mounted) {
        Get.snackbar(
          '🎉 Obrigado!',
          result['message'] ?? 'Feedback enviado com sucesso! Sua opinião é muito importante para nós.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle, color: Colors.green),
          margin: const EdgeInsets.all(16),
        );
        
        // Redireciona para HOME (detectará automaticamente se é visitante)
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAllNamed(AppRoutes.HOME);
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erro',
          'Não foi possível enviar o feedback. Tente novamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildStepContentStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _questionTitle('10. O aplicativo indicou corretamente o local que eu estava procurando.'),
        _likertRow(_q10, (v) => setState(() { _q10 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('11. A rota apresentada correspondia ao trajeto real dentro do campus.'),
        _likertRow(_q11, (v) => setState(() { _q11 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('12. Eu me senti confiante ao usar o aplicativo para me localizar.'),
        _likertRow(_q12, (v) => setState(() { _q12 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('13. O aplicativo facilitou minha experiência de locomoção dentro da universidade.'),
        _likertRow(_q13, (v) => setState(() { _q13 = v; _updateProgress(); })),
        const SizedBox(height: 10),
        _questionTitle('14. Eu recomendaria o UniGo para outros alunos ou visitantes.'),
        _likertRow(_q14, (v) => setState(() { _q14 = v; _updateProgress(); })),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            } else {
              // Voltar para a Home (/) quando estiver no primeiro step
              Get.offAllNamed(AppRoutes.HOME);
            }
          },
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double maxContentWidth = 360;
              final bool isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                // Mobile: todo o espaço abaixo do AppBar deve ser branco e preenchido, com cantos arredondados
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _progressAnimation.value,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE5E5E5),
                                color: const Color(0xFF3C3CC0),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 50), // Gap between progress and legend
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '1 - Discordo totalmente\n5 - Concordo totalmente',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50), // Gap between legend and content
                      _currentStep == 2
                          ? _buildStepContentStep3()
                          : _currentStep == 3
                              ? _buildStepContentStep4()
                              : _buildStepContent(),
                      const SizedBox(height: 50), // Gap between content and button
                      Center(
                        child: SizedBox(
                          width: 220,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentStep < 3) {
                                if (_canContinue) {
                                  setState(() => _currentStep += 1);
                                }
                              } else {
                                _submitFeedback();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canContinue ? const Color(0xFF3C3CC0) : const Color(0xFFD9D9D9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(_currentStep == 3 ? 'ENVIAR' : 'PRÓXIMO'),
                          ),
                        ),
                      ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Telas maiores: mantém o card centralizado ocupando apenas o necessário
              final double containerWidth = maxContentWidth + 32; // 16px padding cada lado
              return Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: containerWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, child) {
                                    return LinearProgressIndicator(
                                      value: _progressAnimation.value,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFE5E5E5),
                                      color: const Color(0xFF3C3CC0),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 50), // Gap between progress and legend
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '1 - Discordo totalmente\n5 - Concordo totalmente',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 50), 
                            _currentStep == 2
                                ? _buildStepContentStep3()
                                : _currentStep == 3
                                    ? _buildStepContentStep4()
                                    : _buildStepContent(),
                            const SizedBox(height: 50), 
                            Center(
                              child: SizedBox(
                                width: 220,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          if (_currentStep < 3) {
                                            if (_canContinue) {
                                              setState(() => _currentStep += 1);
                                            }
                                          } else {
                                            _submitFeedback();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _canContinue && !_isSubmitting
                                        ? const Color(0xFF3C3CC0)
                                        : const Color(0xFFD9D9D9),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(_currentStep == 3 ? 'ENVIAR' : 'PRÓXIMO'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _questionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3C3CC0),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _radioOption(String label, String value, String? groupValue, ValueChanged<String> onChanged) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      dense: true,
      activeColor: const Color(0xFF3C3CC0),
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _likertRow(int? current, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final val = index + 1;
          final bool selected = current == val;
          return GestureDetector(
            onTap: () => onChanged(val),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade600, width: 1.4),
                    color: selected ? const Color(0xFF3C3CC0) : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$val'),
              ],
            ),
          );
        }),
      ),
    );
  }
}

