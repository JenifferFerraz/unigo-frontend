import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env_service.dart';
import 'routes/app_routes.dart';
import 'data/services/auth_service.dart';
import 'data/services/storage_service.dart';
import 'data/services/location_service.dart';
import 'data/services/upload_image_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await EnvService.init();

  await Get.putAsync<StorageService>(() => StorageService().init());
  await Get.putAsync<AuthService>(() => AuthService().init());
  await Get.putAsync(() => LocationService().init());
  Get.put(UploadImagensService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      initialRoute: AppRoutes.SPLASH,
      getPages: AppRoutes.pages,
      debugShowCheckedModeBanner: false,
    );
  }
} 