import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'components/mock_floor_navigation.dart';

class MockFloorNavigationScreen extends StatelessWidget {
  const MockFloorNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Exemplo de dados mockados (substitua pelos dados reais do backend)
    final List<LatLng> pathToStairs = [
      LatLng(-16.293056959, -48.943612758),
      LatLng(-16.293028139, -48.943603795),
      LatLng(-16.292920746, -48.943582082),
      LatLng(-16.292908413, -48.943648638),
      LatLng(-16.2929888, -48.9436656),
    ];
    final List<LatLng> pathFromStairs = [
      LatLng(-16.2929862, -48.943664),
      LatLng(-16.292909051, -48.943648244),
      LatLng(-16.292904222, -48.943673084),
      LatLng(-16.292897346, -48.943704836),
      LatLng(-16.292880976, -48.943779412),
      LatLng(-16.29293898, -48.94379305),
      LatLng(-16.2929341, -48.9438141),
    ];
    final List stairsTransition = [
      [-48.9436656, -16.2929888],
      [-48.943664, -16.2929862],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Simulação de Navegação Multi-Andar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MockFloorNavigation(
          pathToStairs: pathToStairs,
          pathFromStairs: pathFromStairs,
          stairsTransition: stairsTransition,
        ),
      ),
    );
  }
}