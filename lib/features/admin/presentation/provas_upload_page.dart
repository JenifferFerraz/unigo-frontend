import 'package:flutter/material.dart';
import 'admin_spreadsheet_upload.dart';

class ProvasUploadPage extends StatelessWidget {
  const ProvasUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminSpreadsheetUpload(
      title: 'Provas',
      instructions: 'Envie a planilha de provas. Aceito: .xlsx, .xls, .csv',
      uploadEndpoint: '/upload/exams',
      templateType: 'exams',
    );
  }
}
