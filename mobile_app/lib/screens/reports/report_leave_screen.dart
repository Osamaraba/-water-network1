import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';

class ReportLeaveScreen extends StatefulWidget {
  const ReportLeaveScreen({super.key});
  @override
  State<ReportLeaveScreen> createState() => _ReportLeaveScreenState();
}

class _ReportLeaveScreenState extends State<ReportLeaveScreen> {
  final _service = ReportService();
  int _year = DateTime.now().year;
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      _report = await _service.getAdminLeaveReport(year: _year);
    } catch (e) {
      debugPrint('Report error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _changeYear(int delta) {
    setState(() => _year += delta);
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _report?['summary'] as Map<String, dynamic>?;
    final items = (_report?['items'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الإجازات'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeYear(-1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Text('$_year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: () => _changeYear(1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
            ),
          ),
          if (summary != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${summary['total_employees'] ?? 0}', 'موظف', Icons.people),
                    _statItem('${summary['total_requests'] ?? 0}', 'الطلبات', Icons.list),
                    _statItem('${summary['approved'] ?? 0}', 'مقبول', Icons.check_circle, Colors.green),
                    _statItem('${summary['pending'] ?? 0}', 'قيد المراجعة', Icons.pending, Colors.orange),
                    _statItem('${summary['rejected'] ?? 0}', 'مرفوض', Icons.cancel, Colors.red),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('لا توجد بيانات'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final byType = (item['by_type'] as Map<String, dynamic>?) ?? {};
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary,
                                child: Text('${item['employee_number'] ?? ''}'.substring(0, 1), style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(item['employee_number'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('مقبول: ${item['approved'] ?? 0} | قيد: ${item['pending'] ?? 0} | مرفوض: ${item['rejected'] ?? 0}'),
                                  if (byType.isNotEmpty)
                                    Text(
                                      'الأنواع: ${byType.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                              trailing: Text('الإجمالي: ${item['total_requests'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}
