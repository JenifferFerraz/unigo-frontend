import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:image_picker/image_picker.dart';
import '../../core/config/env_service.dart';
import 'dart:async';

class UploadImagensService extends GetxService {
  static UploadImagensService get to => Get.find();
  
  late final CloudinaryPublic cloudinary;

  @override
  void onInit() {
    super.onInit();
    print('Inicializando serviço de upload...');
    print('Cloud Name: ${EnvService.cloudinaryCloudName}');
    print('API Key: ${EnvService.cloudinaryApiKey}');
    
    try {
      cloudinary = CloudinaryPublic(
        EnvService.cloudinaryCloudName,
        EnvService.cloudinaryApiKey,
        cache: false,
      );
      print('Serviço Cloudinary inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar Cloudinary: $e');
      rethrow;
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      print('Iniciando upload da imagem...');
      
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      print('Preparando upload para pasta: unigo/avatars');
      
      CloudinaryFile cloudinaryFile;
      
      if (kIsWeb) {
        // Para ambiente web
        print('Processando imagem para web...');
        final bytes = await image.readAsBytes();
        print('Bytes da imagem lidos com sucesso');
        
        // Criar um arquivo temporário para o upload
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        print('URL do objeto criada: $url');
        
        cloudinaryFile = CloudinaryFile.fromFile(
          url,
          folder: 'unigo/avatars',
        );
        print('CloudinaryFile criado com sucesso');
      } else {
        // Para ambiente mobile
        print('Processando imagem para mobile...');
        final file = File(image.path);
        cloudinaryFile = CloudinaryFile.fromFile(
          file.path,
          folder: 'unigo/avatars',
        );
        print('CloudinaryFile criado com sucesso');
      }

      print('Arquivo preparado para upload');

      print('Iniciando upload para Cloudinary...');
      final response = await cloudinary.uploadFile(cloudinaryFile);
      print('Upload concluído com sucesso!');
      print('URL segura recebida: ${response.secureUrl}');
      print('URL pública recebida: ${response.url}');
      print('Public ID: ${response.publicId}');

      // Verificar se a URL está no formato correto para TwicPics
      if (response.secureUrl != null) {
        final url = response.secureUrl!;
        print('URL formatada para TwicPics: $url');
        
        // Limpar a URL para garantir que está no formato correto
        final cleanUrl = url.replaceAll('http://', 'https://');
        print('URL limpa: $cleanUrl');
        
        Get.back();
        return cleanUrl;
      }

      Get.back();
      return response.secureUrl;
    } catch (e, stackTrace) {
      print('Erro durante o upload: $e');
      print('Stack trace: $stackTrace');
      Get.back();
      Get.snackbar(
        'Erro',
        'Não foi possível fazer o upload da imagem. Verifique suas credenciais do Cloudinary.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
}