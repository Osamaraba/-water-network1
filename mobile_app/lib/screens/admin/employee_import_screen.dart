import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';

class EmployeeImportScreen extends StatefulWidget {
  const EmployeeImportScreen({super.key});

  @override
  State<EmployeeImportScreen> createState() => _EmployeeImportScreenState();
}

class _EmployeeImportScreenState extends State<EmployeeImportScreen> {
  final EmployeeService _service = EmployeeService();
  String? _filePath;
  bool _busy = false;
  Map<String, dynamic>? _lastResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _lastResult = null;
      });
    }
  }

  Future<void> _downloadTemplate({required bool dynamic}) async {
    setState(() => _busy = true);
    try {
      final bytes = await _service.downloadTemplateBytes(dynamic: dynamic);
      final dir = await getApplicationDocumentsDirectory();
      final name = dynamic ? 'employee_template_dynamic.xlsx' : 'employee_template.xlsx';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);

      await OpenFilex.open(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تنزيل القالب وفتحه: $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التنزيل: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار ملف Excel أولاً')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الاستيراد'),
        content: const Text(
          'هل أنت متأكد من استيراد الموظفين من هذا الملف؟\n'
          'سيتم إضافة الموظفين الجدد وتجاهل الأرقام المكررة.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('استيراد')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final result = await _service.bulkImport(_filePath!);
      setState(() => _lastResult = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم بنجاح: ${result['created']} موظف | تخطي: ${result['skipped']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاستيراد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد الموظفين'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppTheme.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('📥 استيراد من Excel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      '1. نزّل القالب (يفضل الديناميكي للبيانات السابقة)\n'
                      '2. افتحه في Excel، واملأ البيانات TOP-DOWN\n'
                      '3. احفظ الملف واختره هنا ثم اضغط استيراد',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('الخطوة 1: تنزيل القالب',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('قالب ديناميكي (مع منسدلات مفلترة)'),
                      onPressed: _busy ? null : () => _downloadTemplate(dynamic: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('قالب ثابت (فارغ)'),
                        onPressed: _busy ? null : () => _downloadTemplate(dynamic: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('الخطوة 2: اختيار الملف',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text(_filePath == null
                            ? 'اختر ملف Excel'
                            : _filePath!.split(Platform.pathSeparator).last),
                        onPressed: _busy ? null : _pickFile,
                      ),
                    ),
                    if (_filePath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '📁 ${_filePath}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              color: const Color(0xFFF9F0E7),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('الخطوة 3: الاستيراد',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('ابدأ الاستيراد الآن'),
                      onPressed: _busy || _filePath == null ? null : _import,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),

            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          const SizedBox(width: 8),
                          const Text('نتيجة الاستيراد',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(),
                      Text('📊 إجمالي الصفوف: ${_lastResult!['total_rows']}'),
                      Text('✅ تم الإنشاء: ${_lastResult!['created']}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('⏭️ تم التخطي: ${_lastResult!['skipped']}',
                        style: const TextStyle(color: Colors.orange)),
                      if ((_lastResult!['errors'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('⚠️ أخطاء:',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ...(_lastResult!['errors'] as List).take(10).map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '• صف ${e['row']} (${e['employee_number']}): ${e['error']}',
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          );
                        }),
                        if ((_lastResult!['errors'] as List).length > 10)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '... و ${(_lastResult!['errors'] as List).length - 10} أخطاء أخرى',
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
