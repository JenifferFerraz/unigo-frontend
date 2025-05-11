import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../../data/services/auth_service.dart';
import '../../../../routes/app_routes.dart';

class Sidebar extends StatelessWidget {
  final AuthService _authService = Get.find<AuthService>();

  Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF3C3CC0),
        child: Column(
          children: [
            Obx(() {
              final user = _authService.currentUser.value;
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF3C3CC0),
                  border: Border(
                    bottom: BorderSide(color: Colors.white24, width: 1),
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF3C3CC0),
                    ),
                  ),
                ),
                accountName: Text(
                  user?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              );
            }),

            _buildMenuItem(
              icon: Icons.location_on,
              title: 'Localização',
              onTap: () => Get.back(),
            ),            _buildMenuItem(
              icon: Icons.schedule,
              title: 'Horário de Aulas',
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.SCHEDULE);
              },
            ),
            _buildMenuItem(
              icon: Icons.event,
              title: 'Eventos',
              onTap: () => Get.back(),
            ),
            _buildMenuItem(
              icon: Icons.assignment,
              title: 'Provas',
              onTap: () => Get.back(),
            ),

            const Spacer(),

            const Divider(color: Colors.white24),
            _buildMenuItem(
              icon: Icons.person,
              title: 'Perfil',
              onTap: () => Get.toNamed(AppRoutes.PROFILE),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _authService.logout();
                  Get.offAllNamed(AppRoutes.LOGIN);
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
