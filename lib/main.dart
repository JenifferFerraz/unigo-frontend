import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/config/env_service.dart';
import 'routes/app_routes.dart';
import 'data/services/auth_service.dart';
import 'data/services/storage_service.dart';
import 'data/services/upload_image_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvService.init();

  await Get.putAsync<StorageService>(() => StorageService().init());
  await Get.putAsync<AuthService>(() => AuthService().init());
  Get.put(UploadImagensService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Detecta a rota inicial baseada na URL atual
  String _getInitialRoute() {
    try {
      final uri = Uri.tryParse(Uri.base.toString());
      if (uri != null) {
        // Para Flutter web com hash routing, o path vem do fragment
        String path = uri.fragment;
        
        // Remove a barra inicial se existir
        if (path.startsWith('/')) {
          path = path.substring(1);
        }
        
        // Se a URL for reset-password com token, vai para a página de confirmação
        if (path.startsWith('reset-password') && uri.queryParameters.containsKey('token')) {
          return AppRoutes.RESET_PASSWORD;
        }
        
        // Se a URL for reset-password sem token, também vai para lá (página de solicitação)
        if (path.startsWith('reset-password')) {
          return AppRoutes.RESET_PASSWORD;
        }
        
        // Verifica também o path normal (sem hash)
        if (uri.path == '/reset-password' && uri.queryParameters.containsKey('token')) {
          return AppRoutes.RESET_PASSWORD;
        }
        
        if (uri.path == '/reset-password') {
          return AppRoutes.RESET_PASSWORD;
        }
      }
    } catch (e) {
      // Em caso de erro, usa a rota padrão
    }
    
    return AppRoutes.SPLASH;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: EnvService.appName,
      theme: ThemeData(
        primaryColor: const Color(0xFF3C3CC0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3C3CC0),
        ),
      ),
      initialRoute: _getInitialRoute(),
      getPages: AppRoutes.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
