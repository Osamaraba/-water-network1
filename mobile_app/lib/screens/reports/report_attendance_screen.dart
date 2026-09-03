import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/report_pdf.dart';

class ReportAttendanceScreen extends StatefulWidget {
  const ReportAttendanceScreen({super.key});
  @override
  State<ReportAttendanceScreen> createState() => _ReportAttendanceScreenState();
}

class _ReportAttendanceScreenState extends State<ReportAttendanceScreen> {
  final _service = ReportService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      _report = await _service.getAdminAttendanceReport(
        startDate: _fmtDate(_startDate),
        endDate: _fmtDate(_endDate),
      );
    } catch (e) {
      debugPrint('Report error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = d;
          if (_startDate.isAfter(_endDate)) _startDate = _endDate;
        }
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _report?['summary'] as Map<String, dynamic>?;
    final items = (_report?['items'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الحضور والانصراف'),
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
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'من', border: OutlineInputBorder(), isDense: true,
                        ),
                        child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'إلى', border: OutlineInputBorder(), isDense: true,
                        ),
                        child: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                      ),
                    ),
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
                    _statItem('${summary['total_present'] ?? 0}', 'حاضر', Icons.check_circle),
                    _statItem('${summary['total_late'] ?? 0}', 'متأخر', Icons.access_time),
                    _statItem('${summary['attendance_rate'] ?? 0}%', 'النسبة', Icons.percent),
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
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary,
                                child: Text('${item['employee_number'] ?? ''}'.substring(0, 1), style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(item['employee_name'] ?? ''),
                              subtitle: Text('حضور: ${item['present'] ?? 0} | تأخر: ${item['late'] ?? 0} | ساعات: ${item['total_hours'] ?? 0}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${item['attendance_rate'] ?? 0}%', style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (item['attendance_rate'] ?? 0) >= 90 ? Colors.green : Colors.orange,
                                  )),
                                  const Text('النسبة', style: TextStyle(fontSize: 10)),
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

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}
