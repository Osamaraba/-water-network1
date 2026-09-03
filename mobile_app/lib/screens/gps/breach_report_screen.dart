import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/employee.dart';
import '../../utils/report_pdf.dart';
import '../../theme/app_theme.dart';

class BreachReportScreen extends StatefulWidget {
  const BreachReportScreen({super.key});

  @override
  State<BreachReportScreen> createState() => _BreachReportScreenState();
}

class _BreachReportScreenState extends State<BreachReportScreen> {
  final _gps = GpsService();
  final _empService = EmployeeService();
  bool _loading = true;
  List<Map<String, dynamic>> _breaches = [];
  List<Employee> _employees = [];
  int? _filterEmp;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final parts = <String>[];
    if (h > 0) parts.add('$h س');
    if (m > 0) parts.add('$m د');
    if (s > 0 || parts.isEmpty) parts.add('$s ث');
    return parts.join(' ');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _employees = await _empService.listEmployees();
      await _refresh();
    } catch (e) {
      debugPrint('breach load: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    try {
      final res = await _gps.getBreaches(employeeId: _filterEmp);
      _breaches = List<Map<String, dynamic>>.from(res['items'] ?? []);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('breach refresh: $e');
    }
  }

  Future<void> _print() async {
    try {
      await ReportPdf.shareBreaches(_breaches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر الطباعة: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل خروقات منطقة العمل'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير PDF',
            onPressed: _breaches.isEmpty ? null : _print,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                        labelText: 'تصفية حسب الموظف', border: OutlineInputBorder()),
                    value: _filterEmp,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('جميع الموظفين')),
                      ..._employees.map((e) => DropdownMenuItem(
                          value: e.employeeId,
                          child: Text('${e.fullName} (${e.employeeNumber})'))),
                    ],
                    onChanged: (v) {
                      _filterEmp = v;
                      _refresh();
                    },
                  ),
                ),
                Expanded(
                  child: _breaches.isEmpty
                      ? const Center(
                          child: Text('لا توجد خروقات مسجلة',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _breaches.length,
                          itemBuilder: (ctx, i) {
                            final b = _breaches[i];
                            final start = DateTime.tryParse(b['started_at'] ?? '');
                            final end = DateTime.tryParse(b['ended_at'] ?? '');
                            final dur = (b['duration_seconds'] ?? 0).toDouble();
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.warning, color: Colors.orange),
                                title: Text(b['full_name'] ?? ''),
                                subtitle: Text(
                                    'من ${_t(start)} إلى ${_t(end)}\nالمسافة: ${(b['distance_m'] ?? 0).toStringAsFixed(0)} م'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(_fmt(Duration(
                                      seconds: dur.toInt()))),
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

  String _t(DateTime? d) => d == null ? '' : d.toString().substring(0, 19);
}
