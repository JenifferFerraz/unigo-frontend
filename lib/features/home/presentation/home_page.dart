import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/atoms/map/map_widget.dart';
import '../../../core/atoms/loading_screen.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import './components/sidebar.dart';
import './components/location_search.dart';
import './components/feedback_tab.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/models/navigation_model.dart';


class HomePage extends StatefulWidget {
  final bool showSearch;
  const HomePage({Key? key, this.showSearch = false}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showLocationSearch = false;
  
  // Método para abrir dialog de seleção de andar manualmente
  Future<void> _showFloorSelectionDialog() async {
    final locationService = Get.find<LocationService>();
    final nearest = locationService.nearestStructure.value;
    
    if (nearest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não está próximo de nenhuma estrutura')),
      );
      return;
    }
    
    if (nearest['floors'] == null || nearest['floors'] is! List || (nearest['floors'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estrutura sem andares disponíveis')),
      );
      return;
    }
    
    final floors = List<int>.from(nearest['floors']);
    
    if (floors.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Esta estrutura tem apenas o andar ${floors[0]}')),
      );
      return;
    }
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha o andar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: floors.map((f) => ListTile(
              title: Text('Andar $f'),
              onTap: () => Navigator.of(context).pop(f),
            )).toList(),
          ),
        );
      },
    );
    
    if (selected != null) {
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
          print('[HomePage] Erro ao enviar posição para WebSocket: $e');
        }
      }
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
                  if (Get.isRegistered<LocationService>()) {
                    final locationService = Get.find<LocationService>();
                    locationService.clearAllData();
                  }
                  
                  if (Get.isRegistered<WebSocketService>()) {
                    final wsService = Get.find<WebSocketService>();
                    await wsService.disconnect();
                    await wsService.clearSessionId();
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

          if (isVisitor) const FeedbackTab(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Obx(() {
            final isNavigating = controller?.isNavigating.value ?? false;
            final nearest = controller?.nearestStructure.value;
            final multiFloor = controller?.multiFloorStage.value != null && controller!.multiFloorStage.value != MultiFloorNavigationStage.none;
            final floors = (nearest != null && nearest['floors'] != null) ? List<int>.from(nearest['floors']) : <int>[];
            
            if (!isNavigating) return const SizedBox.shrink();

            return Column(
              children: [
                FloatingActionButton.extended(
                  heroTag: "btnStopNav",
                  onPressed: () {
                    controller?.stopNavigation();
                    Get.snackbar(
                      'Navegação Cancelada',
                      'A rota foi removida',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red[400],
                      colorText: Colors.white,
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  backgroundColor: Colors.red[400],
                  label: const Text(
                    'Parar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const SizedBox(height: 12),

                if (floors.length > 1)
                  FloatingActionButton.extended(
                    heroTag: "btnChooseFloor",
                    onPressed: () async {
                      final selected = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Escolha o andar para navegação'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: floors.map((f) => ListTile(
                                title: Text('Andar $f'),
                                onTap: () => Navigator.of(context).pop(f),
                              )).toList(),
                            ),
                          );
                        },
                      );
                      if (selected != null) {
                        final pos = controller?.currentPosition.value;
                        if (pos != null && nearest != null) {
                          try {
                            final locService = controller;
                            if (locService != null) {
                              final selectedFloorPath = locService.getPathForFloor(selected);
                              
                              // Mostrar a rota do andar
                              if (selectedFloorPath != null && selectedFloorPath.isNotEmpty) {
                                
                                double totalDistance = 0.0;
                                for (int i = 1; i < selectedFloorPath.length; i++) {
                                  totalDistance += Distance().as(
                                    LengthUnit.Meter, 
                                    selectedFloorPath[i - 1], 
                                    selectedFloorPath[i]
                                  );
                                }
                                
                                // Atualizar rota exibida (mantendo o destination)
                                final currentDestination = locService.activeRoute.value?.destination;
                                locService.activeRoute.value = NavigationRoute(
                                  steps: [],
                                  totalDistance: totalDistance,
                                  estimatedDuration: (totalDistance / 1.4).toInt(),
                                  path: selectedFloorPath,
                                  destination: currentDestination,
                                );
                                
                                // Atualizar rooms do andar selecionado
                                final nearestStruct = locService.nearestStructure.value;
                                if (nearestStruct != null && nearestStruct['roomsByFloor'] != null) {
                                  final roomsByFloor = nearestStruct['roomsByFloor'] as Map<String, dynamic>;
                                  final floorKey = selected.toString();
                                  
                                  if (roomsByFloor.containsKey(floorKey) && roomsByFloor[floorKey] is List) {
                                    locService.roomsOnFloor.assignAll(List<Map<String, dynamic>>.from(roomsByFloor[floorKey]));
                                  }
                                }
                                
                                // Manter estágio de navegação multi-andar ativo
                                if (locService.multiFloorStage.value == MultiFloorNavigationStage.none) {
                                  locService.multiFloorStage.value = MultiFloorNavigationStage.toStairs;
                                }
                              } else {
                                // FALLBACK: Se floorPaths não estiver disponível, usa lógica antiga
                                if (selected == locService.destinationFloor && locService.pathFromStairs.isNotEmpty) {
                                  locService.activeRoute.value = NavigationRoute(
                                    steps: [],
                                    totalDistance: 0,
                                    estimatedDuration: 0,
                                    path: locService.pathFromStairs,
                                  );
                                } else if (locService.pathToStairs.isNotEmpty) {
                                  locService.activeRoute.value = NavigationRoute(
                                    steps: [],
                                    totalDistance: 0,
                                    estimatedDuration: 0,
                                    path: locService.pathToStairs,
                                  );
                                }
                              }
                            }
                          } catch (e) {
                            print('[HomePage] Erro ao enviar posição para WebSocket ou atualizar rota: $e');
                          }
                        }
                      }
                    },
                    backgroundColor: Colors.blue[400],
                    label: const Text(
                      'Mudar Andar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: const Icon(Icons.layers, color: Colors.white),
                  ),
                if (floors.length > 1)
                  const SizedBox(height: 12),
              ],
            );
          }),
          Obx(() {
            final isNavigating = controller?.isNavigating.value ?? false;
            final nearest = controller?.nearestStructure.value;
            
            // Mostrar botão sempre que houver estrutura próxima e NÃO estiver navegando
            if (isNavigating || nearest == null) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton.extended(
                heroTag: "btnSelectFloor",
                onPressed: _showFloorSelectionDialog,
                backgroundColor: Colors.orange[700],
                label: const Text(
                  'Selecionar Andar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.layers, color: Colors.white),
              ),
            );
          }),
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
        ],
      ),
    );
  }

}
