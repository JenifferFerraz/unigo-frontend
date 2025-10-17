import 'package:flutter/material.dart';

class AdminUploadPage extends StatelessWidget {
  const AdminUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizar Provas/Eventos'),
      ),
      body: Center(
        child: Text('Página de upload para admins'),
      ),
    );
  }
}
