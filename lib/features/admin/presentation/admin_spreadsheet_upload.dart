import 'dart:io';

import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/admin_upload_service.dart';

class AdminSpreadsheetUpload extends StatefulWidget {
  final String title;
  final String instructions;
  final String uploadEndpoint;
  final String? templateType;

  const AdminSpreadsheetUpload({
    Key? key,
    required this.title,
    required this.instructions,
    required this.uploadEndpoint,
    this.templateType,
  }) : super(key: key);

  @override
  State<AdminSpreadsheetUpload> createState() => _AdminSpreadsheetUploadState();
}

class _AdminSpreadsheetUploadState extends State<AdminSpreadsheetUpload> {
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String? _statusMessage;
  String? _preview;

  Future<void> _pickFile() async {
    _statusMessage = null;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (result == null) return;

    final file = result.files.first;

    setState(() {
      _pickedFile = file;
      _preview = null;
    });

    try {
      final path = file.path;
      if (path == null) return;

      if ((file.extension ?? '').toLowerCase() == 'csv') {
        final content = await File(path).readAsString();
        final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
        if (lines.isNotEmpty) {
          setState(() {
            _preview = 'Linhas: ${lines.length}\nCabeçalho: ${lines.first}';
          });
        }
      } else {
        try {
          final bytes = await File(path).readAsBytes();
          final excel = Excel.decodeBytes(bytes);
          final sheet = excel.tables.keys.isNotEmpty ? excel.tables[excel.tables.keys.first] : null;
          if (sheet != null && sheet.rows.isNotEmpty) {
            final header = sheet.rows.first.map((c) => c?.value ?? '').join(', ');
            setState(() {
              _preview = 'Linhas (planilha): ${sheet.maxRows}\nCabeçalho: $header';
            });
          }
        } catch (_) {
        }
      }
    } catch (_) {}
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null) {
      setState(() {
        _statusMessage = 'Selecione um arquivo antes de enviar.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = null;
    });

    try {
      final service = AdminUploadService();
      final endpoint = widget.uploadEndpoint.startsWith('/')
          ? widget.uploadEndpoint
          : '/${widget.uploadEndpoint}';
      final response = await service.uploadSpreadsheet(
        endpoint: endpoint,
        file: _pickedFile!,
      );

      // Extrair informações do resultado
      final data = response.data as Map<String, dynamic>;
      final totalRows = data['totalRows'] ?? 0;
      final successCount = data['successCount'] ?? 0;
      final errorCount = data['errorCount'] ?? 0;

      setState(() {
        _statusMessage = 'Upload concluído!\n'
            'Total: $totalRows | Sucesso: $successCount | Erros: $errorCount';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao enviar arquivo: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _downloadTemplate() async {
    if (widget.templateType == null) return;

    try {
      final service = AdminUploadService();
      final response = await service.downloadTemplate(widget.templateType!);

      // Aqui você pode implementar o download do arquivo
      // Para web, use package:universal_html ou file_saver
      // Para mobile, use path_provider e salve o arquivo

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download iniciado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar template: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const appBlue = Color(0xFF3C3CC0);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Logo.png',
              height: 36,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(widget.title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(widget.instructions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: appBlue,
                side: const BorderSide(color: appBlue, width: 1.5),
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                elevation: 0,
              ),
              onPressed: widget.templateType == null ? null : _downloadTemplate,
              icon: const Icon(Icons.download),
              label: const Text('Baixar Planilha-Modelo'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: appBlue,
                side: const BorderSide(color: appBlue, width: 1.5),
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                elevation: 0,
              ),
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Anexar Arquivo'),
            ),
            const SizedBox(height: 12),
            if (_pickedFile != null)
              Card(
                child: ListTile(
                  title: Text(_pickedFile!.name),
                  subtitle: Text('${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _isUploading
                        ? null
                        : () => setState(() {
                              _pickedFile = null;
                            }),
                  ),
                ),
              ),
            if (_preview != null) ...[
              const SizedBox(height: 8),
              Text('Pré-visualização:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(_preview!),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                elevation: 2,
              ),
              onPressed: _isUploading ? null : _uploadFile,
              child: _isUploading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enviar este arquivo'),
            ),
            const SizedBox(height: 12),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(color: _statusMessage!.startsWith('Erro') ? Colors.red : Colors.green),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
