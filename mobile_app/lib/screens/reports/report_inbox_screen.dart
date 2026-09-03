import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../services/auth_provider.dart';
import '../../models/attendance.dart';
import '../../theme/app_theme.dart';
import '../../utils/report_pdf.dart';

class ReportInboxScreen extends StatefulWidget {
  const ReportInboxScreen({super.key});

  @override
  State<ReportInboxScreen> createState() => _ReportInboxScreenState();
}

class _ReportInboxScreenState extends State<ReportInboxScreen> {
  List<ReportInboxItem> _items = [];
  bool _loading = true;
  String? _statusFilter;
  String? _employeeFilter;
  DateTime? _dateFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await ReportService().getInbox(
        status: _statusFilter,
        date: _dateFilter == null
            ? null
            : '${_dateFilter!.year}-${_dateFilter!.month.toString().padLeft(2, '0')}-${_dateFilter!.day.toString().padLeft(2, '0')}',
        employeeNumber: _employeeFilter == null || _employeeFilter!.isEmpty
            ? null
            : _employeeFilter,
      );
    } catch (e) {
      debugPrint('inbox error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _employeeFilter = null;
      _dateFilter = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('تقارير الوارد'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        labelText: 'رقم الموظف', border: OutlineInputBorder()),
                    onChanged: (v) => _employeeFilter = v.trim(),
                    onSubmitted: (_) => _load(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          decoration: const InputDecoration(
                              labelText: 'الحالة', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('الكل')),
                            DropdownMenuItem(value: 'submitted', child: Text('جديد')),
                            DropdownMenuItem(value: 'reviewed', child: Text('تمت المراجعة')),
                          ],
                          onChanged: (v) {
                            _statusFilter = v;
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateFilter ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dateFilter = picked);
                              _load();
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'التاريخ', border: OutlineInputBorder()),
                            child: Text(
                              _dateFilter == null
                                  ? 'اختر'
                                  : '${_dateFilter!.day}/${_dateFilter!.month}/${_dateFilter!.year}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white),
                          child: const Text('تطبيق الفلتر'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('مسح'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('لا توجد تقارير مطابقة'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final r = _items[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                  backgroundColor: AppTheme.primary,
                                  child: Icon(Icons.description, color: Colors.white)),
                              title: Text(r.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('من: ${r.authorName} (${r.authorNumber})'),
                                  if (r.description != null && r.description!.isNotEmpty)
                                    Text(r.description!,
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                  Text('التاريخ: ${r.reportDate ?? r.createdAt}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: r.status == 'submitted'
                                          ? Colors.blue.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                        r.status == 'submitted' ? 'جديد' : r.status,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share, color: AppTheme.primary),
                                    tooltip: 'مشاركة عبر واتساب (PDF)',
                                    onPressed: () {
                                      final profile =
                                          context.read<AuthProvider>().profile;
                                      ReportPdf.shareInboxItem(
                                        r,
                                        profile?.fullName ?? '',
                                        profile?.employeeNumber ?? '',
                                      ).catchError((e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('تعذر المشاركة: $e')));
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
