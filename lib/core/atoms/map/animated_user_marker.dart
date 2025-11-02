import 'package:flutter/material.dart';

/// Marcador animado de localização do usuário
/// Com pulso animado e sombra
class AnimatedUserMarker extends StatefulWidget {
  const AnimatedUserMarker({Key? key}) : super(key: key);

  @override
  State<AnimatedUserMarker> createState() => _AnimatedUserMarkerState();
}

class _AnimatedUserMarkerState extends State<AnimatedUserMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador de animação com duração de 2 segundos, repetindo infinitamente
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Animação de pulso: cresce de 1.0 para 1.8
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Animação de opacidade: diminui conforme cresce
    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de pulso animado (onda)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3C3CC0).withOpacity(_opacityAnimation.value),
                  ),
                ),
              );
            },
          ),
          
          // Círculo externo fixo (borda branca)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          
          // Círculo médio (borda azul)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3C3CC0),
            ),
          ),
          
          // Ponto central branco
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          
          // Ícone de pessoa (opcional - pode comentar se preferir apenas círculos)
          Icon(
            Icons.person,
            size: 16,
            color: const Color(0xFF3C3CC0),
          ),
        ],
      ),
    );
  }
}
