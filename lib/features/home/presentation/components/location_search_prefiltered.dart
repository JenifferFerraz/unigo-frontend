import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/location_service.dart';
import '../../../../data/models/structure_model.dart';
import '../../../../routes/app_routes.dart';
import 'location_search.dart';

class LocationSearchPreFiltered extends StatefulWidget {
  const LocationSearchPreFiltered({Key? key}) : super(key: key);

  @override
  State<LocationSearchPreFiltered> createState() => _LocationSearchPreFilteredState();
}

class _LocationSearchPreFilteredState extends State<LocationSearchPreFiltered> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    
    // Verifica se deve iniciar navegação automaticamente
    final args = Get.arguments;
    if (args != null && args['autoNavigate'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAutoNavigation(args);
      });
    }
  }

  /// Processa navegação automática
  Future<void> _handleAutoNavigation(Map<String, dynamic> args) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // Obtém structureId dos argumentos
      final structureId = args['structureId'] as int?;
      
      if (structureId == null || structureId <= 0) {
        _showError('ID da estrutura inválido');
        return;
      }

      // Verifica se LocationService está disponível
      if (!Get.isRegistered<LocationService>()) {
        _showError('Serviço de localização não disponível');
        return;
      }

      final locationService = Get.find<LocationService>();

      // Verifica se há localização ativa
      final hasLocation = locationService.currentPosition.value != null;

      if (!hasLocation) {
        // Sem localização: oferece visualizar ou ativar
        final action = await _showLocationDialog();
        
        if (action == 'enable') {
          final enabled = await _requestLocationPermission();
          if (!enabled) return;
        } else if (action == 'view') {
          // Apenas visualiza sem navegação
          await _navigateToHomeWithStructure(structureId, visualizeOnly: true);
          return;
        } else {
          return; // Cancelou
        }
      }

      // Com localização: navega automaticamente
      await _navigateToHomeWithStructure(structureId, visualizeOnly: false);
      
    } catch (e) {
      print('[LocationSearchPreFiltered] Erro na navegação automática: $e');
      _showError('Erro ao iniciar navegação: $e');
    } finally {
      _isNavigating = false;
    }
  }

  /// Navega para a home com a estrutura selecionada
  Future<void> _navigateToHomeWithStructure(
    int structureId, 
    {bool visualizeOnly = false}
  ) async {
    try {
      final locationService = Get.find<LocationService>();

      // Volta para a home com os argumentos de navegação
      Get.offAllNamed(
        AppRoutes.HOME,
        arguments: {
          'navigateToStructure': true,
          'structureId': structureId,
          'visualizeOnly': visualizeOnly,
        },
      );

      // Aguarda a home carregar e processar
      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {
      print('[LocationSearchPreFiltered] Erro ao navegar para home: $e');
      _showError('Erro ao navegar: $e');
    }
  }

  /// Mostra dialog sobre localização desativada
  Future<String?> _showLocationDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_off, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Localização Desativada')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para navegar até a sala, é necessário ativar sua localização.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'O que deseja fazer?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('view'),
            child: const Text('Apenas Visualizar', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop('enable'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C3CC0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.location_on, color: Colors.white),
            label: const Text('Ativar e Navegar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Solicita permissão de localização
  Future<bool> _requestLocationPermission() async {
    try {
      final locationService = Get.find<LocationService>();
      
      // Mostra loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Obtendo sua localização...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final permission = await locationService.requestLocationPermission();
      
      Get.back(); // Fecha loading

      if (permission) {
        _showSuccess('✓ Localização ativada com sucesso!');
        return true;
      } else {
        _showError('Permissão de localização negada');
        return false;
      }
    } catch (e) {
      Get.back(); // Fecha loading em caso de erro
      _showError('Erro ao ativar localização: $e');
      return false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    Get.snackbar(
      'Sucesso',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final initialQuery = args != null && args['query'] != null ? args['query'] as String : '';
    final autoNavigate = args != null && args['autoNavigate'] == true;
    final structure = args != null && args['structure'] != null ? args['structure'] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Estrutura'),
        backgroundColor: const Color(0xFF3C3CC0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LocationSearch(
          initialQuery: initialQuery,
          autoNavigate: autoNavigate,
          structure: structure,
        ),
      ),
    );
  }
}