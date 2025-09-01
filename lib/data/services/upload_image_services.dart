import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:async';

class UploadImagensService extends GetxService {
  static UploadImagensService get to => Get.find();  Future<String?> uploadImage(XFile image) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      String base64String;
      
      // Usa apenas métodos que funcionam tanto na web quanto no mobile
      final bytes = await image.readAsBytes();
      
      if (bytes.length > 500 * 1024) {
        final quality = (500 * 1024 * 100 / bytes.length).round();
        
        if (kIsWeb) {
          // Para web, comprime usando compressWithList
          final compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            quality: quality,
            format: CompressFormat.jpeg,
          );
          base64String = base64Encode(compressedBytes);
        } else {
          // Para mobile, tenta comprimir o arquivo, mas com fallback
          try {
            final compressedBytes = await FlutterImageCompress.compressWithList(
              bytes,
              quality: quality,
              format: CompressFormat.jpeg,
            );
            base64String = base64Encode(compressedBytes);
          } catch (e) {
            // Fallback: usa os bytes originais se a compressão falhar
            base64String = base64Encode(bytes);
          }
        }
      } else {
        base64String = base64Encode(bytes);
      }

      final imageString = 'data:image/jpeg;base64,$base64String';
      
      Get.back();
      return imageString;
      
    } catch (e) {
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