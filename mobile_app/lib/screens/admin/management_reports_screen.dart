import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../services/api_service.dart';
import '../../services/report_share_service.dart';
import '../../models/employee.dart';
import '../../theme/app_theme.dart';

class ManagementReportsScreen extends StatefulWidget {
  const ManagementReportsScreen({super.key});

  @override
  State<ManagementReportsScreen> createState() => _ManagementReportsScreenState();
}

class _ManagementReportsScreenState extends State<ManagementReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الإدارية'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'الحضور', icon: Icon(Icons.access_time)),
            Tab(text: 'الإجازات', icon: Icon(Icons.event_note)),
            Tab(text: 'المغادرات', icon: Icon(Icons.exit_to_app)),
            Tab(text: 'العمل الإضافي', icon: Icon(Icons.timer)),
            Tab(text: 'الملف الكامل', icon: Icon(Icons.person_search)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AttendanceReportTab(),
          LeaveReportTab(),
          ShortLeaveReportTab(),
          OvertimeReportTab(),
          FullProfileTab(),
        ],
      ),
    );
  }
}

mixin _ExportMixin {
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _exportAndShare(
    BuildContext context, {
    required String apiPath,
    required String filename,
    required String reportTitle,
    String? subtitle,
  }) async {
    _snack(context, 'جاري تحميل التقرير...', success: true);
    try {
      final response = await apiService.downloadBytes(apiPath);
      if (response.statusCode == 200) {
        final file = await ReportShareService.saveReportFile(
          response.bodyBytes,
          filename,
        );
        await ReportShareService.showShareDialog(
          context,
          file: file,
          reportTitle: '$reportTitle - $subtitle',
        );
      } else {
        _snack(context, 'فشل التحميل: ${response.statusCode}');
      }
    } catch (e) {
      _snack(context, 'خطأ: $e');
    }
  }
}

class AttendanceReportTab extends StatefulWidget {
  const AttendanceReportTab({super.key});

  @override
  State<AttendanceReportTab> createState() => _AttendanceReportTabState();
}

class _AttendanceReportTabState extends State<AttendanceReportTab>
    with _ExportMixin {
  List<Employee> _employees = [];
  bool _loading = true;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  Employee? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _employees = await EmployeeService().listEmployees();
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2024),
      lastDate: isFrom ? _toDate : DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = d;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = d;
      }
    });
  }

  String _dayName(DateTime d) {
    const days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    return days[d.weekday % 7];
  }

  Future<void> _exportToExcel() async {
    final from = _fmt(_fromDate);
    final to = _fmt(_toDate);
    final empId = _selectedEmployee?.employeeId;
    var path = '/reports-extended/attendance?from=$from&to=$to&format=xlsx';
    if (empId != null) path += '&employee_id=$empId';
    final empName = _selectedEmployee?.fullName ?? 'جميع الموظفين';
    final subtitle = 'من ${_dayName(_fromDate)} $from إلى ${_dayName(_toDate)} $to | $empName';
    await _exportAndShare(
      context,
      apiPath: path,
      filename: 'attendance_report_$from\_$to.xlsx',
      reportTitle: 'تقرير الحضور',
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<Employee>(
                          value: _selectedEmployee,
                          hint: const Text('جميع الموظفين'),
                          decoration: const InputDecoration(
                            labelText: 'الموظف', border: OutlineInputBorder(),
                          ),
                          items: _employees.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('${e.fullName} (${e.employeeNumber})'),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedEmployee = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _DatePickerField(
                              label: 'من تاريخ',
                              date: _fromDate,
                              dayName: _dayName(_fromDate),
                              onTap: () => _pickDate(true),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _DatePickerField(
                              label: 'إلى تاريخ',
                              date: _toDate,
                              dayName: _dayName(_toDate),
                              onTap: () => _pickDate(false),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ExportButtons(
                  reportName: 'الحضور',
                  onExport: _exportToExcel,
                ),
              ],
            ),
          );
  }
}

class LeaveReportTab extends StatefulWidget {
  const LeaveReportTab({super.key});

  @override
  State<LeaveReportTab> createState() => _LeaveReportTabState();
}

class _LeaveReportTabState extends State<LeaveReportTab> with _ExportMixin {
  bool _loading = true;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _toDate = DateTime.now();
  String? _status;

  @override
  void initState() {
    super.initState();
    _loading = false;
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = d;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = d;
      }
    });
  }

  String _dayName(DateTime d) {
    const days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    return days[d.weekday % 7];
  }

  Future<void> _exportToExcel() async {
    final from = _fmt(_fromDate);
    final to = _fmt(_toDate);
    String path = '/reports-extended/leave?from=$from&to=$to&format=xlsx';
    if (_status != null) path += '&status=$_status';
    final subtitle = 'من ${_dayName(_fromDate)} $_fromDate إلى ${_dayName(_toDate)} $_toDate${_status != null ? ' | الحالة: $_status' : ''}';
    await _exportAndShare(
      context,
      apiPath: path,
      filename: 'leave_report_$from\_$to.xlsx',
      reportTitle: 'تقرير الإجازات',
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _status,
                          hint: const Text('جميع الحالات'),
                          decoration: const InputDecoration(
                            labelText: 'حالة الإجازة', border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                            DropdownMenuItem(value: 'approved', child: Text('معتمدة')),
                            DropdownMenuItem(value: 'rejected', child: Text('مرفوضة')),
                          ],
                          onChanged: (v) => setState(() => _status = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _DatePickerField(
                              label: 'من تاريخ',
                              date: _fromDate,
                              dayName: _dayName(_fromDate),
                              onTap: () => _pickDate(true),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _DatePickerField(
                              label: 'إلى تاريخ',
                              date: _toDate,
                              dayName: _dayName(_toDate),
                              onTap: () => _pickDate(false),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ExportButtons(
                  reportName: 'الإجازات',
                  onExport: _exportToExcel,
                ),
              ],
            ),
          );
  }
}

class ShortLeaveReportTab extends StatefulWidget {
  const ShortLeaveReportTab({super.key});

  @override
  State<ShortLeaveReportTab> createState() => _ShortLeaveReportTabState();
}

class _ShortLeaveReportTabState extends State<ShortLeaveReportTab>
    with _ExportMixin {
  bool _loading = true;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _toDate = DateTime.now();
  String? _status;
  String? _kind;

  @override
  void initState() {
    super.initState();
    _loading = false;
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = d;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = d;
      }
    });
  }

  String _dayName(DateTime d) {
    const days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    return days[d.weekday % 7];
  }

  Future<void> _exportToExcel() async {
    final from = _fmt(_fromDate);
    final to = _fmt(_toDate);
    String path = '/reports-extended/short-leaves?from=$from&to=$to&format=xlsx';
    if (_status != null) path += '&status=$_status';
    if (_kind != null) path += '&kind=$_kind';
    String subtitle = 'من ${_dayName(_fromDate)} $_fromDate إلى ${_dayName(_toDate)} $_toDate';
    if (_kind != null) subtitle += ' | النوع: ${_kind == "official" ? "رسمية" : "خاصة"}';
    if (_status != null) subtitle += ' | الحالة: $_status';
    await _exportAndShare(
      context,
      apiPath: path,
      filename: 'short_leaves_report_$from\_$to.xlsx',
      reportTitle: 'تقرير المغادرات القصيرة',
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _kind,
                                hint: const Text('الكل'),
                                decoration: const InputDecoration(
                                  labelText: 'نوع المغادرة', border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'official', child: Text('رسمية')),
                                  DropdownMenuItem(value: 'personal', child: Text('خاصة')),
                                ],
                                onChanged: (v) => setState(() => _kind = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _status,
                                hint: const Text('الكل'),
                                decoration: const InputDecoration(
                                  labelText: 'الحالة', border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                                  DropdownMenuItem(value: 'approved', child: Text('معتمدة')),
                                  DropdownMenuItem(value: 'rejected', child: Text('مرفوضة')),
                                ],
                                onChanged: (v) => setState(() => _status = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _DatePickerField(
                              label: 'من تاريخ',
                              date: _fromDate,
                              dayName: _dayName(_fromDate),
                              onTap: () => _pickDate(true),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _DatePickerField(
                              label: 'إلى تاريخ',
                              date: _toDate,
                              dayName: _dayName(_toDate),
                              onTap: () => _pickDate(false),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ExportButtons(
                  reportName: 'المغادرات القصيرة',
                  onExport: _exportToExcel,
                ),
              ],
            ),
          );
  }
}

class OvertimeReportTab extends StatefulWidget {
  const OvertimeReportTab({super.key});

  @override
  State<OvertimeReportTab> createState() => _OvertimeReportTabState();
}

class _OvertimeReportTabState extends State<OvertimeReportTab>
    with _ExportMixin {
  bool _loading = true;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String? _status;

  @override
  void initState() {
    super.initState();
    _loading = false;
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = d;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = d;
      }
    });
  }

  String _dayName(DateTime d) {
    const days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    return days[d.weekday % 7];
  }

  Future<void> _exportToExcel() async {
    final from = _fmt(_fromDate);
    final to = _fmt(_toDate);
    String path = '/reports-extended/overtime?from=$from&to=$to&format=xlsx';
    if (_status != null) path += '&status=$_status';
    final subtitle = 'من ${_dayName(_fromDate)} $_fromDate إلى ${_dayName(_toDate)} $_toDate${_status != null ? ' | الحالة: $_status' : ''}';
    await _exportAndShare(
      context,
      apiPath: path,
      filename: 'overtime_report_$from\_$to.xlsx',
      reportTitle: 'تقرير العمل الإضافي',
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _status,
                          hint: const Text('جميع الحالات'),
                          decoration: const InputDecoration(
                            labelText: 'حالة العمل الإضافي', border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                            DropdownMenuItem(value: 'approved', child: Text('معتمد')),
                            DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                            DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                          ],
                          onChanged: (v) => setState(() => _status = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _DatePickerField(
                              label: 'من تاريخ',
                              date: _fromDate,
                              dayName: _dayName(_fromDate),
                              onTap: () => _pickDate(true),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _DatePickerField(
                              label: 'إلى تاريخ',
                              date: _toDate,
                              dayName: _dayName(_toDate),
                              onTap: () => _pickDate(false),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ExportButtons(
                  reportName: 'العمل الإضافي',
                  onExport: _exportToExcel,
                ),
              ],
            ),
          );
  }
}

class FullProfileTab extends StatefulWidget {
  const FullProfileTab({super.key});

  @override
  State<FullProfileTab> createState() => _FullProfileTabState();
}

class _FullProfileTabState extends State<FullProfileTab> with _ExportMixin {
  List<Employee> _employees = [];
  bool _loading = true;
  Employee? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _employees = await EmployeeService().listEmployees();
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportToExcel() async {
    if (_selectedEmployee == null) {
      _snack(context, 'اختر الموظف أولاً');
      return;
    }
    final path =
        '/reports-extended/full-profile/${_selectedEmployee!.employeeId}?format=xlsx';
    await _exportAndShare(
      context,
      apiPath: path,
      filename:
          'employee_${_selectedEmployee!.employeeNumber}_full_profile.xlsx',
      reportTitle: 'الملف الكامل',
      subtitle: _selectedEmployee!.fullName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.person_search,
                            size: 64, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        const Text(
                          'تقرير الملف الكامل للموظف',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يتضمن: البيانات الشخصية، الحضور، الإجازات، العمل الإضافي، المخالفات، التتبع، التوزيع، الصيانة',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Employee>(
                          value: _selectedEmployee,
                          hint: const Text('اختر الموظف'),
                          decoration: const InputDecoration(
                            labelText: 'الموظف', border: OutlineInputBorder(),
                          ),
                          items: _employees.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('${e.fullName} (${e.employeeNumber})'),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedEmployee = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ExportButtons(
                  reportName: 'الملف الكامل',
                  onExport: _exportToExcel,
                ),
              ],
            ),
          );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final String dayName;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.dayName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('$date'),
          ],
        ),
      ),
    );
  }
}

class _ExportButtons extends StatelessWidget {
  final String reportName;
  final VoidCallback onExport;

  const _ExportButtons({required this.reportName, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14),
          ),
          onPressed: onExport,
          icon: const Icon(Icons.download),
          label: Text('تصدير ومشاركة تقرير $reportName',
              style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}
