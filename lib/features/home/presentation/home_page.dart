import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/map/map_widget.dart';
import '../../../core/atoms/loading_screen.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import './components/sidebar.dart';
import './components/location_search.dart';
import './components/feedback_tab.dart';
import '../../../data/services/websocket_service.dart';


class HomePage extends StatefulWidget {
  final bool showSearch;
  const HomePage({Key? key, this.showSearch = false}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationService = Get.isRegistered<LocationService>() ? Get.find<LocationService>() : null;
    if (locationService != null) {
      ever(locationService.nearestStructure, (nearest) async {
        if (nearest != null && nearest['floors'] != null && nearest['floors'] is List && (nearest['floors'] as List).isNotEmpty) {
          final floors = List<int>.from(nearest['floors']);
          // Se só tem um andar, seleciona automaticamente
          if (floors.length == 1) {
            setState(() {
              _selectedLayer = floors[0];
            });
            // Envia para o websocket (fluxo já implementado no LocationService)
          } else {
            // Exibe dialog para o usuário escolher o andar
            final selected = await showDialog<int>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Escolha o andar'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: floors.map((f) => ListTile(
                      title: Text(_layerNames.length > f ? _layerNames[f] : 'Andar $f'),
                      onTap: () => Navigator.of(context).pop(f),
                    )).toList(),
                  ),
                );
              },
            );
            if (selected != null) {
              setState(() {
                _selectedLayer = selected;
              });
              // Envia para o websocket com o andar escolhido
              final pos = locationService.currentPosition.value;
              if (pos != null) {
                try {
                  WebSocketService ws;
                  if (!Get.isRegistered<WebSocketService>()) {
                    ws = Get.put(WebSocketService());
                    await ws.connect();
                  } else {
                    ws = Get.find<WebSocketService>();
                    if (!ws.isConnected.value) {
                      await ws.connect();
                    }
                  }
                  if (ws.isConnected.value) {
                    ws.sendPosition(
                      position: [pos.longitude, pos.latitude],
                      structureId: nearest['id'],
                      floor: selected,
                    );
                  }
                } catch (e) {
                  print('[HomePage] Erro ao enviar posição para WebSocket após escolha de andar: $e');
                }
              }
            }
          }
        }
      });
    }
  }
  @override
  void initState() {
    super.initState();
    // Garante que o WebSocketService está conectado
    Future.microtask(() async {
      try {
        final ws = Get.isRegistered<WebSocketService>() ? Get.find<WebSocketService>() : null;
        if (ws != null && !ws.isConnected.value) {
          await ws.connect();
        } else if (ws == null) {
          final newWs = Get.put(WebSocketService());
          await newWs.connect();
        }
      } catch (e) {
        print('[HomePage] Erro ao conectar WebSocketService: $e');
      }
    });
  }
  int _selectedLayer = 0;
  final List<String> _layerNames = [
    '1º Andar',
    '2º Andar',
    '3º Andar',
  ];

  bool _showLocationSearch = false;

  void _toggleLayer() {
    setState(() {
      _selectedLayer = (_selectedLayer + 1) % _layerNames.length;
    });
  }

  @override
  Widget build(BuildContext context) {
  // Verifica se é visitante: sem usuário autenticado OU argumento visitor=true
  final authService = Get.find<AuthService>();
  final isVisitor = authService.currentUser.value == null || 
                     (Get.arguments != null && Get.arguments['visitor'] == true);

    LocationService? controller;
    try {
      controller = Get.find<LocationService>();
    } catch (e) {
      controller = null;
    }
    if (controller == null) {
      Future.microtask(() async {
        final loc = await Get.putAsync(() => LocationService().init());
        final hasPermission = await loc.requestLocationPermission();
        if (hasPermission == true) {
          await loc.getCurrentLocation();
        }
        setState(() {});
      });
      return const LoadingScreen(message: 'Carregando localização...');
    }
    Future.microtask(() async {
      final hasPermission = await controller?.requestLocationPermission();
      if (hasPermission == true) {
        await controller?.getCurrentLocation();
      }
    });
   
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        leading: isVisitor
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  // Limpa dados do visitante antes de sair
                  print('[HomePage] Visitante saindo, limpando dados...');
                  
                  if (Get.isRegistered<LocationService>()) {
                    final locationService = Get.find<LocationService>();
                    locationService.clearAllData();
                    print('[HomePage] ✓ LocationService limpo');
                  }
                  
                  if (Get.isRegistered<WebSocketService>()) {
                    final wsService = Get.find<WebSocketService>();
                    await wsService.disconnect();
                    await wsService.clearSessionId();
                    print('[HomePage] ✓ WebSocket desconectado');
                  }
                  
                  Get.offAllNamed(AppRoutes.ACCESS_SELECTION);
                },
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
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
      drawer: isVisitor ? null : Sidebar(),
      body: Stack(
        children: [
          SizedBox.expand(
            child: MapWidget(
              zoom: 15.0,
              showUserLocation: true,
              selectedLayer: _selectedLayer,
            ),
          ),
          if (_showLocationSearch)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: LocationSearch(),
            ),
  
          Obx(() {
            final position = controller?.currentPosition.value;
            if (position == null) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.orange[100],
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Localização não ativada. Para uma experiência completa, permita o acesso à localização.',
                          style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Mostra loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const LoadingScreen(
                              message: 'Obtendo sua localização...',
                            ),
                          );
                          
                          try {
                            // Solicita permissão
                            final permission = await controller?.requestLocationPermission();
                            
                            if (permission == true) {
                              // Se permissão concedida, obtém localização
                              await controller?.getCurrentLocation();
                              
                              // Aguarda até ter precisão adequada ou timeout
                              int attempts = 0;
                              while (attempts < 10) {
                                await Future.delayed(const Duration(milliseconds: 500));
                                final currentPos = controller?.currentPosition.value;
                                if (currentPos != null && currentPos.accuracy <= 20) {
                                  // Localização com boa precisão obtida
                                  break;
                                }
                                attempts++;
                              }
                              
                              // Fecha loading
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              
                              // Mostra sucesso
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Localização ativada com sucesso!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              // Permissão negada
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      controller?.error.value ?? 
                                      'Permissão de localização negada. Por favor, ative nas configurações do dispositivo.',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            // Erro ao obter localização
                            if (mounted && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao obter localização: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Ativar', style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Aba lateral de Feedback para visitantes
          if (isVisitor) const FeedbackTab(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnSearch",
            onPressed: () {
              setState(() {
                _showLocationSearch = !_showLocationSearch;
              });
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.search, color: Color(0xFF3C3CC0)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "btnLayer",
            onPressed: _toggleLayer,
            backgroundColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers, color: Colors.blue),
                Text(_layerNames[_selectedLayer], style: TextStyle(fontSize: 10, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
