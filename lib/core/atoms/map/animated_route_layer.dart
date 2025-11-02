import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AnimatedRouteLayer extends StatefulWidget {
  final List<LatLng> routePoints;

  const AnimatedRouteLayer({
    Key? key,
    required this.routePoints,
  }) : super(key: key);

  @override
  State<AnimatedRouteLayer> createState() => _AnimatedRouteLayerState();
}

class _AnimatedRouteLayerState extends State<AnimatedRouteLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;
        
        return Stack(
          children: [
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  color: const Color(0xFF4285F4).withOpacity(0.15 * pulseValue),
                  strokeWidth: 20.0 * pulseValue,
                  borderStrokeWidth: 0.0,
                  isDotted: false,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
            
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  color: Colors.black.withOpacity(0.2),
                  strokeWidth: 12.0,
                  borderStrokeWidth: 0.0,
                  isDotted: false,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
            
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  gradientColors: [
                    const Color(0xFF4285F4),
                    const Color(0xFF5E9AFF), 
                    const Color(0xFF4285F4),
                  ],
                  strokeWidth: 8.0,
                  borderStrokeWidth: 0.0,
                  isDotted: false,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
            
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  color: const Color(0xFF5E9AFF).withOpacity(0.6 * (2 - pulseValue)),
                  strokeWidth: 3.0 * (2 - pulseValue),
                  borderStrokeWidth: 0.0,
                  isDotted: false,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
