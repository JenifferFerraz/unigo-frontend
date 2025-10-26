import 'package:get/get.dart';
import 'package:unigo_mobile/data/services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MockFloorNavigation extends StatefulWidget {
  final List<LatLng> pathToStairs;
  final List<LatLng> pathFromStairs;
  final List stairsTransition;

  const MockFloorNavigation({
    Key? key,
    required this.pathToStairs,
    required this.pathFromStairs,
    required this.stairsTransition,
  }) : super(key: key);

  @override
  State<MockFloorNavigation> createState() => _MockFloorNavigationState();
}

class _MockFloorNavigationState extends State<MockFloorNavigation> {
  bool onFirstFloor = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          onFirstFloor ? 'Andar atual: Térreo' : 'Andar atual: 2º Andar',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Text(
              onFirstFloor
                  ? 'Exibindo rota até a escada...\n${widget.pathToStairs.length} pontos'
                  : 'Exibindo rota do topo da escada até a sala...\n${widget.pathFromStairs.length} pontos',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Envia a posição do início do pathToStairs para o WebSocket
            if (widget.pathToStairs.isNotEmpty) {
              final pos = widget.pathToStairs.first;
              try {
                Get.find<WebSocketService>().sendPosition(
                  position: [pos.latitude, pos.longitude],
                  structureId: null,
                  floor: null,
                );
              } catch (e) {
                print('Erro ao enviar posição mock para o WebSocket: $e');
              }
            }
          },
          child: const Text('Enviar posição mock para WebSocket'),
        ),
        if (onFirstFloor)
          ElevatedButton(
            onPressed: () {
              setState(() {
                onFirstFloor = false;
              });
            },
            child: const Text('Subir escada'),
          )
        else
          ElevatedButton(
            onPressed: () {
              setState(() {
                onFirstFloor = true;
              });
            },
            child: const Text('Voltar para o térreo'),
          ),
        const SizedBox(height: 16),
        Text('Stairs transition: ${widget.stairsTransition}'),
      ],
    );
  }
}
