import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../routes/app_routes.dart';

class Sidebar extends StatelessWidget {
  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Colors.white24,
    );
  }
  final AuthService _authService = Get.find<AuthService>();

  Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isVisitor = (Get.arguments != null && Get.arguments['visitor'] == true);
    return Drawer(
      child: Container(
        color: const Color(0xFF3C3CC0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: Icons.location_on,
                title: 'Localização',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.LOCATION_SEARCH);
                },
              ),
              const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.schedule,
                title: 'Horário de Aulas',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.SCHEDULE);
                },
              ),
              const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.event_note,
                title: 'Eventos',
                onTap: () {
                  Get.back();
                  // Navegação futura
                },
              ),
              const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.calendar_today,
                title: 'Calendário',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.CALENDAR);
                },
              ),
              const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.assignment,
                title: 'Provas',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.EXAMS);
                },
              ),
              if (_authService.currentUser.value?.role == 'admin') ...[
                const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
                _buildMenuItem(
                  icon: Icons.upload_file,
                  title: 'Atualizar Provas/Eventos',
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.ADMIN_UPLOAD);
                  },
                ),
              ],
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _authService.logout();
                    Get.offAllNamed(AppRoutes.ACCESS_SELECTION);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3C3CC0),
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}