import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../data/admin_upload_service.dart';
import '../../home/presentation/components/sidebar.dart';

typedef TableEditCallback = void Function(Map<String, dynamic> item);
typedef TableDeleteCallback = void Function(Map<String, dynamic> item);
typedef UploadSuccessCallback = void Function();

class TableColumn {
  final String label;
  final String field;
  const TableColumn({required this.label, required this.field});
}
class AdminSpreadsheetUpload extends StatefulWidget {
  final String title;
  final String instructions;
  final String uploadEndpoint;
  final String? templateType;
  final List<Map<String, dynamic>>? tableData;
  final List<TableColumn>? tableColumns;
  final TableEditCallback? onEdit;
  final TableDeleteCallback? onDelete;
  final UploadSuccessCallback? onUploadSuccess;

  const AdminSpreadsheetUpload({
    Key? key,
    required this.title,
    required this.instructions,
    required this.uploadEndpoint,
    this.templateType,
    this.tableData,
    this.tableColumns,
    this.onEdit,
    this.onDelete,
    this.onUploadSuccess,
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
      withData: true, 
    );
    if (result == null) return;

    final file = result.files.first;

    setState(() {
      _pickedFile = file;
      _preview = null;
    });

    try {
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _statusMessage = 'Erro: não foi possível ler o arquivo. Certifique-se de que o arquivo foi selecionado corretamente.';
        });
        return;
      }

      if ((file.extension ?? '').toLowerCase() == 'csv') {
        final content = String.fromCharCodes(bytes);
        final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
        if (lines.isNotEmpty) {
          final headerParts = lines.first.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          setState(() {
            _preview = 'Linhas: ${lines.length}\nCabeçalho: ${headerParts.join(', ')}';
          });
        }
      } else {
        try {
          final excel = Excel.decodeBytes(bytes);
          final sheet = excel.tables.keys.isNotEmpty ? excel.tables[excel.tables.keys.first] : null;
          if (sheet != null && sheet.rows.isNotEmpty) {
            final headerParts = sheet.rows.first
                .map((c) => c?.value?.toString().trim() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            setState(() {
              _preview = 'Linhas (planilha): ${sheet.maxRows}\nCabeçalho: ${headerParts.join(', ')}';
            });
          }
        } catch (_) {}
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

    final fileBytes = _pickedFile!.bytes;
    if (fileBytes == null || fileBytes.isEmpty) {
      setState(() {
        _statusMessage = 'Erro: arquivo não tem dados. Tente selecionar o arquivo novamente.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = null;
    });

    try {
      final cleanFile = PlatformFile(
        name: _pickedFile!.name,
        size: _pickedFile!.size,
        bytes: fileBytes,
      );

      final service = AdminUploadService();
      final endpoint = widget.uploadEndpoint.startsWith('/')
          ? widget.uploadEndpoint
          : '/${widget.uploadEndpoint}';
      final response = await service.uploadSpreadsheet(
        endpoint: endpoint,
        file: cleanFile,
      );

      final data = response.data as Map<String, dynamic>;
      final totalRows = data['totalRows'] ?? 0;
      final successCount = data['successCount'] ?? 0;
      final errorCount = data['errorCount'] ?? 0;

      setState(() {
        _statusMessage = 'Upload concluído!\n'
            'Total: $totalRows | Sucesso: $successCount | Erros: $errorCount';
        _pickedFile = null; // Limpa o arquivo após upload bem-sucedido
        _preview = null;
      });

      // Chama callback de sucesso para atualizar a lista
      if (widget.onUploadSuccess != null && successCount > 0) {
        widget.onUploadSuccess!();
      }

      // Mostra snackbar de sucesso
      if (mounted && successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $successCount ${successCount == 1 ? 'registro importado' : 'registros importados'} com sucesso!'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

      final bytes = response.data is List<int>
          ? Uint8List.fromList(response.data as List<int>)
          : response.data as Uint8List;

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'planilha_modelo_${widget.templateType}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Planilha baixada!')),
          );
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/planilha_modelo_${widget.templateType}.xlsx');
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Planilha salva em: ${file.path}')),
          );
        }
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
      backgroundColor: const Color(0xFFF5F7FA),
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
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      drawer: Sidebar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.upload_file, color: appBlue, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.instructions,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.templateType != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: appBlue,
                          side: BorderSide(color: appBlue.withOpacity(0.3), width: 1.5),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _downloadTemplate,
                        icon: const Icon(Icons.download_rounded, size: 22),
                        label: const Text('Baixar Planilha-Modelo'),
                      ),
                    if (widget.templateType != null) const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: appBlue,
                        side: BorderSide(color: appBlue.withOpacity(0.3), width: 1.5),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: _isUploading ? null : _pickFile,
                      icon: const Icon(Icons.attach_file_rounded, size: 22),
                      label: const Text('Anexar Arquivo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_pickedFile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appBlue.withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.description_rounded, color: appBlue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile!.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                        onPressed: _isUploading
                            ? null
                            : () => setState(() {
                                  _pickedFile = null;
                                  _preview = null;
                                }),
                      ),
                    ],
                  ),
                ),
              if (_preview != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.visibility_rounded, color: appBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pré-visualização',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: appBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _preview!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  elevation: 4,
                  shadowColor: appBlue.withOpacity(0.4),
                ),
                onPressed: _isUploading ? null : _uploadFile,
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cloud_upload_rounded, size: 22),
                          SizedBox(width: 8),
                          Text('Enviar este arquivo'),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusMessage!.startsWith('Erro')
                        ? Colors.red[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusMessage!.startsWith('Erro')
                          ? Colors.red[300]!
                          : Colors.green[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusMessage!.startsWith('Erro')
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: _statusMessage!.startsWith('Erro')
                            ? Colors.red[700]
                            : Colors.green[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusMessage!.startsWith('Erro')
                                ? Colors.red[900]
                                : Colors.green[900],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.tableData != null && widget.tableColumns != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: appBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.table_chart_rounded, color: appBlue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Dados Cadastrados',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                                    columnSpacing: 24,
                                    horizontalMargin: 16,
                                    columns: [
                                      ...widget.tableColumns!.map((col) => DataColumn(
                                        label: Text(
                                          col.label,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      )),
                                      const DataColumn(
                                        label: Text('Ações', style: TextStyle(fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                    rows: widget.tableData!.map<DataRow>((item) {
                                      return DataRow(cells: [
                                        ...widget.tableColumns!.map((col) {
                                          final value = item[col.field]?.toString() ?? '';
                                          final isLongField = ['title', 'description', 'location', 'link', 'subject'].contains(col.field);
                                          return DataCell(
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: isLongField ? 200 : 150,
                                              ),
                                              child: Text(
                                                value,
                                                maxLines: isLongField ? 2 : 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (widget.onEdit != null)
                                                IconButton(
                                                  icon: const Icon(Icons.edit_rounded, size: 20),
                                                  color: appBlue,
                                                  tooltip: 'Editar',
                                                  onPressed: () => widget.onEdit!(item),
                                                ),
                                              if (widget.onDelete != null)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_rounded, size: 20),
                                                  color: Colors.red[400],
                                                  tooltip: 'Deletar',
                                                  onPressed: () => widget.onDelete!(item),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),                       
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}