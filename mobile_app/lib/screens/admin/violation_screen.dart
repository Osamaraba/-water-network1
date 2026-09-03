import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/services.dart';
import '../../models/employee.dart';
import '../../models/violation.dart';
import '../../theme/app_theme.dart';
import '../../services/report_share_service.dart';

class ViolationScreen extends StatefulWidget {
  const ViolationScreen({super.key});
  @override
  State<ViolationScreen> createState() => _ViolationScreenState();
}

class _ViolationScreenState extends State<ViolationScreen> {
  List<Employee> _employees = [];
  List<Violation> _violations = [];
  Employee? _selected;
  final _typeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _penalty = 'alert1';
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _loading = true;
  bool _sending = false;
  String? _filterStatus;
  int? _filterEmployeeId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final keepId = _selected?.employeeId;
    try {
      final results = await Future.wait([
        EmployeeService().listEmployees(),
        ViolationService().getAll(status: _filterStatus, employeeId: _filterEmployeeId),
      ]);
      _employees = results[0] as List<Employee>;
      _violations = results[1] as List<Violation>;
      if (keepId != null) {
        _selected = _employees.where((e) => e.employeeId == keepId).isEmpty
            ? null
            : _employees.firstWhere((e) => e.employeeId == keepId);
      }
    } catch (e) {
      debugPrint('load violation error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _penaltyLabel(String v) =>
      Violation.penaltyOptions.firstWhere((o) => o['value'] == v,
          orElse: () => {'label': v})['label']!;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  String _fmtDate() =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
  String _fmtTime() =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  String _buildMessage(String employeeName) =>
      'إشعار مخالفة\nالموظف: $employeeName\nنوع المخالفة: ${_typeCtrl.text}\n'
      'التاريخ: ${_fmtDate()}\nالساعة: ${_fmtTime()}\nالعقوبة: ${_penaltyLabel(_penalty)}\n'
      '${_notesCtrl.text.isNotEmpty ? 'ملاحظات: ${_notesCtrl.text}' : ''}';

  Future<void> _send({bool whatsapp = false}) async {
    if (_selected == null) {
      _snack('اختر الموظف أولاً');
      return;
    }
    if (_typeCtrl.text.isEmpty) {
      _snack('أدخل نوع المخالفة');
      return;
    }
    setState(() => _sending = true);
    try {
      await ViolationService().createViolation(
        employeeId: _selected!.employeeId,
        violationType: _typeCtrl.text,
        violationDate: _fmtDate(),
        violationTime: _fmtTime(),
        penalty: _penalty,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      );
      if (whatsapp && _selected!.phone != null && _selected!.phone!.isNotEmpty) {
        final phone = _selected!.phone!.replaceAll(RegExp(r'[^\d]'), '');
        final uri = Uri.parse(
            'https://wa.me/$phone?text=${Uri.encodeComponent(_buildMessage(_selected!.fullName))}');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
      _snack(whatsapp ? 'تم الإرسال وفي انتظار واتساب' : 'تم إرسال إشعار المخالفة بانتظار رد الموظف',
          color: Colors.green);
      _typeCtrl.clear();
      _notesCtrl.clear();
      await _load();
    } catch (e) {
      _snack('تعذر الإرسال: $e');
    }
    setState(() => _sending = false);
  }

  void _snack(String m, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: color ?? AppTheme.danger));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'acknowledged':
        return Colors.green;
      case 'disputed':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('إصدار مخالفة / عقوبة'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              onSelected: (val) {
                setState(() => _filterStatus = val);
                _load();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: null, child: Text('الكل')),
                ...Violation.statusOptions.map((o) =>
                    PopupMenuItem(value: o['value'], child: Text(o['label']!))),
              ],
            ),
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<Employee>(
                            value: _selected,
                            hint: const Text('اختر الموظف'),
                            isExpanded: true,
                            items: _employees
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text('${e.fullName} (${e.employeeNumber})')))
                                .toList(),
                            onChanged: (v) => setState(() => _selected = v),
                            decoration: const InputDecoration(
                              labelText: 'الموظف',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _typeCtrl,
                            decoration: const InputDecoration(
                                labelText: 'نوع المخالفة', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                        labelText: 'التاريخ', border: OutlineInputBorder()),
                                    child: Text(_fmtDate()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickTime,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                        labelText: 'الساعة', border: OutlineInputBorder()),
                                    child: Text(_fmtTime()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _penalty,
                            decoration: const InputDecoration(
                                labelText: 'العقوبة', border: OutlineInputBorder()),
                            items: Violation.penaltyOptions
                                .map((o) => DropdownMenuItem(
                                    value: o['value'], child: Text(o['label']!)))
                                .toList(),
                            onChanged: (v) => setState(() => _penalty = v ?? 'alert1'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white),
                                  onPressed: _sending ? null : () => _send(),
                                  icon: const Icon(Icons.send),
                                  label: const Text('إرسال'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white),
                                  onPressed: _sending ? null : () => _send(whatsapp: true),
                                  icon: const Icon(Icons.chat),
                                  label: const Text('واتساب'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المخالفات الصادرة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${_violations.length} مخالفة',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_violations.isEmpty)
                    const Text('لا توجد مخالفات بعد')
                  else
                    ..._violations.map((v) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              v.acknowledged ? Icons.check_circle : Icons.warning,
                              color: _statusColor(v.status),
                            ),
                            title: Text(
                                '${v.employeeName ?? "موظف #${v.employeeId}"} — ${v.penaltyLabel}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.violationType),
                                Text(
                                  '${v.violationDate} ${v.violationTime}'
                                  '  •  ${v.statusLabel}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                if (v.employeeResponse != null && v.employeeResponse!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '📝 ${v.employeeResponse}',
                                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) async {
                                if (val == 'delete') {
                                  // TODO: delete
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'status',
                                  child: Text('الحالة: ${v.statusLabel}'),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
