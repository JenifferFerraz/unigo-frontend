import 'package:flutter/material.dart';
import 'admin_spreadsheet_upload.dart';

class EventosUploadPage extends StatelessWidget {
  const EventosUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminSpreadsheetUpload(
      title: 'Eventos',
      instructions: 'Envie a planilha de eventos. Aceito: .xlsx, .xls, .csv',
      uploadEndpoint: '/upload/events',
      templateType: 'events',
    );
  }
}
