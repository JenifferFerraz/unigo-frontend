import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class UploadImagensService extends GetxService {
  static UploadImagensService get to => Get.find();

  Future<String?> uploadImage(XFile image) async {
    try {
      print('Iniciando processamento da imagem...');
      
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      String base64String;
      
      if (kIsWeb) {
        print('Processando imagem para web...');
        final bytes = await image.readAsBytes();
        base64String = base64Encode(bytes);
        print('Imagem convertida para base64 com sucesso');
      } else {
        print('Processando imagem para mobile...');
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        base64String = base64Encode(bytes);
        print('Imagem convertida para base64 com sucesso');
      }

      // Adiciona o prefixo data:image para uso direto em tags img
      final imageString = 'data:image/jpeg;base64,$base64String';
      
      Get.back();
      return imageString;
      
    } catch (e, stackTrace) {
      print('Erro durante o processamento: $e');
      print('Stack trace: $stackTrace');
      Get.back();
      Get.snackbar(
        'Erro',
        'Não foi possível processar a imagem.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
}