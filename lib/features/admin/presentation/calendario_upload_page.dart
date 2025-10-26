import 'package:flutter/material.dart';
import 'admin_spreadsheet_upload.dart';

class CalendarioUploadPage extends StatelessWidget {
  const CalendarioUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminSpreadsheetUpload(
      title: 'Calendário',
      instructions: 'Envie a planilha de calendário. Aceito: .xlsx, .xls, .csv',
  uploadEndpoint: '/admin/upload/calendario',
      downloadUrl: '',
    );
  }
}
