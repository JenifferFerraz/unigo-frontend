import 'package:flutter/material.dart';
import 'admin_spreadsheet_upload.dart';

class HorarioUploadPage extends StatelessWidget {
  const HorarioUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminSpreadsheetUpload(
      title: 'Horário de Aulas',
      instructions: 'Envie a planilha de horário. Aceito: .xlsx, .xls, .csv',
  uploadEndpoint: '/admin/upload/horario',
      downloadUrl: '',
    );
  }
}
