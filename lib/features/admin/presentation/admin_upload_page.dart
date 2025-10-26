import 'dart:io';

import '../data/admin_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';

class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appBlue = Color(0xFF3C3CC0);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: appBlue,
            padding: const EdgeInsets.only(top: 48, bottom: 16),
            child: Center(
              child: Image.asset(
                'assets/images/Logo.png',
                height: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminNavButton(
                  icon: Icons.location_on,
                  label: 'Localização',
                  color: appBlue,
                  onTap: () => Get.toNamed(AppRoutes.LOCATION_SEARCH),
                ),
                const SizedBox(height: 20),
                _AdminNavButton(
                  icon: Icons.schedule,
                  label: 'Horário de Aulas',
                  color: appBlue,
                  onTap: () => Get.toNamed(AppRoutes.ADMIN_UPLOAD_HORARIO),
                ),
                const SizedBox(height: 20),
                _AdminNavButton(
                  icon: Icons.campaign,
                  label: 'Eventos',
                  color: appBlue,
                  onTap: () => Get.toNamed(AppRoutes.ADMIN_UPLOAD_EVENTOS),
                ),
                const SizedBox(height: 20),
                _AdminNavButton(
                  icon: Icons.calendar_month,
                  label: 'Calendário',
                  color: appBlue,
                  onTap: () => Get.toNamed(AppRoutes.ADMIN_UPLOAD_CALENDARIO),
                ),
                const SizedBox(height: 20),
                _AdminNavButton(
                  icon: Icons.check_circle,
                  label: 'Provas',
                  color: appBlue,
                  onTap: () => Get.toNamed(AppRoutes.ADMIN_UPLOAD_PROVAS),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _AdminNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _AdminNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        elevation: 2,
      ),
      icon: Icon(icon, size: 24),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
