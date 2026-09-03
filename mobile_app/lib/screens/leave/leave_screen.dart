import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../models/attendance.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = LeaveService();

  List<LeaveRequest> _leaves = [];
  List<ShortLeaveRequest> _shortLeaves = [];
  bool _loading = true;
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isManager = Provider.of<AuthProvider>(context, listen: false).isManager;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getMyLeaves(),
        _service.getMyShortLeaves(),
      ]);
      _leaves = results[0] as List<LeaveRequest>;
      _shortLeaves = results[1] as List<ShortLeaveRequest>;
    } catch (e) {
      debugPrint('Load leaves error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _statusLabel(String s) {
    if (s == 'approved') return 'معتمدة';
    if (s == 'rejected') return 'مرفوضة';
    return 'قيد المراجعة';
  }

  Color _statusColor(String s) {
    if (s == 'approved') return Colors.green;
    if (s == 'rejected') return Colors.red;
    return Colors.orange;
  }

  String _leaveTypeLabel(String type, String? label) {
    if (label != null && label.isNotEmpty) return label;
    final labels = {
      'annual': 'سنوية',
      'sick': 'مرضية',
      'unpaid': 'بدون راتب',
      'maternity': 'أمومة',
      'paternity': 'أبوة',
      'other': 'أخرى',
      'PRIVATE': 'خاصة',
      'OFFICIAL': 'رسمية',
    };
    return labels[type] ?? type;
  }

  Map<String, int> _getYearlyLeaveStats() {
    final now = DateTime.now();
    int approved = 0;
    int pending = 0;
    int rejected = 0;
    for (var l in _leaves) {
      try {
        final d = DateTime.parse(l.startDate);
        if (d.year == now.year) {
          if (l.status == 'approved') {
            approved++;
          } else if (l.status == 'pending') {
            pending++;
          } else if (l.status == 'rejected') {
            rejected++;
          }
        }
      } catch (_) {}
    }
    return {'approved': approved, 'pending': pending, 'rejected': rejected};
  }

  Map<String, int> _getYearlyShortLeaveStats() {
    final now = DateTime.now();
    int approved = 0;
    int pending = 0;
    int rejected = 0;
    for (var s in _shortLeaves) {
      try {
        final d = DateTime.parse(s.outingDate);
        if (d.year == now.year) {
          if (s.status == 'approved') {
            approved++;
          } else if (s.status == 'pending') {
            pending++;
          } else if (s.status == 'rejected') {
            rejected++;
          }
        }
      } catch (_) {}
    }
    return {'approved': approved, 'pending': pending, 'rejected': rejected};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإجازات والمغادرات'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'إجازات كاملة', icon: Icon(Icons.event_busy)),
            Tab(text: 'مغادرات قصيرة', icon: Icon(Icons.exit_to_app)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeavesList(),
                _buildShortLeavesList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateBottomSheet(),
      ),
    );
  }

  Widget _buildLeavesList() {
    final stats = _getYearlyLeaveStats();
    final now = DateTime.now();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إحصائيات ${now.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('معتمدة', stats['approved'] ?? 0, Colors.green),
                      _buildStatItem('قيد المراجعة', stats['pending'] ?? 0, Colors.orange),
                      _buildStatItem('مرفوضة', stats['rejected'] ?? 0, Colors.red),
                      _buildStatItem('الكل', _leaves.where((l) {
                        try { return DateTime.parse(l.startDate).year == now.year; } catch (_) { return false; }
                      }).length, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _leaves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('لا توجد طلبات إجازة', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _leaves.length,
                    itemBuilder: (context, i) {
                      final l = _leaves[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    l.leaveType == 'sick'
                                        ? Icons.local_hospital
                                        : l.leaveType == 'annual'
                                            ? Icons.beach_access
                                            : Icons.event_note,
                                    color: _statusColor(l.status),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _leaveTypeLabel(l.leaveType, l.leaveTypeLabel),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(_statusLabel(l.status),
                                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    backgroundColor: _statusColor(l.status),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('من', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        Text(l.startDay, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(l.startDate, style: TextStyle(color: Colors.grey[800])),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward, color: Colors.grey[400]),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('إلى', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        Text(l.endDay, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(l.endDate, style: TextStyle(color: Colors.grey[800])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (l.reason != null && l.reason!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('السبب: ${l.reason}', style: TextStyle(color: Colors.grey[700])),
                              ],
                              if (l.leaveTypeCustom != null && l.leaveTypeCustom!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('تفاصيل: ${l.leaveTypeCustom}', style: TextStyle(color: Colors.grey[700])),
                              ],
                              if (_isManager && l.status == 'pending' && l.employeeName != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      label: const Text('اعتماد', style: TextStyle(color: Colors.green)),
                                      onPressed: () => _reviewLeave(l, 'approved'),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      label: const Text('رفض', style: TextStyle(color: Colors.red)),
                                      onPressed: () => _reviewLeave(l, 'rejected'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildShortLeavesList() {
    final stats = _getYearlyShortLeaveStats();
    final now = DateTime.now();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إحصائيات ${now.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('معتمدة', stats['approved'] ?? 0, Colors.green),
                      _buildStatItem('قيد المراجعة', stats['pending'] ?? 0, Colors.orange),
                      _buildStatItem('مرفوضة', stats['rejected'] ?? 0, Colors.red),
                      _buildStatItem('الكل', _shortLeaves.where((s) {
                        try { return DateTime.parse(s.outingDate).year == now.year; } catch (_) { return false; }
                      }).length, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _shortLeaves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.exit_to_app, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('لا توجد مغادرات قصيرة', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _shortLeaves.length,
                    itemBuilder: (context, i) {
                      final s = _shortLeaves[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    s.leaveKind == 'official'
                                        ? Icons.flag
                                        : Icons.person,
                                    color: _statusColor(s.status),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.leaveKindLabel ?? s.leaveKind,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  if (s.trackingRequired)
                                    Chip(
                                      avatar: const Icon(Icons.gps_fixed, size: 14, color: Colors.white),
                                      label: const Text('GPS', style: TextStyle(fontSize: 11, color: Colors.white)),
                                      backgroundColor: Colors.teal,
                                    ),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text(_statusLabel(s.status),
                                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    backgroundColor: _statusColor(s.status),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('التاريخ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        Text(s.outingDay, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(s.outingDate, style: TextStyle(color: Colors.grey[800])),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text('المغادرة', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        Text(s.departureTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward, color: Colors.grey[400]),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text('العودة', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        Text(s.returnTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (s.destination != null && s.destination!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('الوجهة: ${s.destination}', style: TextStyle(color: Colors.grey[700])),
                              ],
                              if (s.reason != null && s.reason!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('السبب: ${s.reason}', style: TextStyle(color: Colors.grey[700])),
                              ],
                              if (s.trackingRequired && s.trackingAcknowledged) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.teal.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.gps_fixed, color: Colors.teal.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'تم تأكيد تفعيل تتبع GPS خلال هذه المغادرة',
                                          style: TextStyle(color: Colors.teal.shade700, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_isManager && s.status == 'pending' && s.employeeName != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      label: const Text('اعتماد', style: TextStyle(color: Colors.green)),
                                      onPressed: () => _reviewShortLeave(s, 'approved'),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      label: const Text('رفض', style: TextStyle(color: Colors.red)),
                                      onPressed: () => _reviewShortLeave(s, 'rejected'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateLeaveSheet(
        service: _service,
        onDone: _loadData,
      ),
    );
  }

  Future<void> _reviewLeave(LeaveRequest l, String status) async {
    final note = await showDialog<String>(
      context: context,
      builder: (c) {
        final noteCtrl = TextEditingController();
        return AlertDialog(
          title: Text(status == 'approved' ? 'تأكيد الاعتماد' : 'تأكيد الرفض'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'ملاحظة (اختياري)',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => noteCtrl.text = v,
            controller: noteCtrl,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(c, noteCtrl.text),
              child: Text(status == 'approved' ? 'اعتماد' : 'رفض'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    try {
      await _service.reviewLeave(l.requestId, status, note: note);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر: $e')));
      }
    }
  }

  Future<void> _reviewShortLeave(ShortLeaveRequest s, String status) async {
    try {
      await _service.reviewShortLeave(s.shortLeaveId, status);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر: $e')));
      }
    }
  }
}

class _CreateLeaveSheet extends StatefulWidget {
  final LeaveService service;
  final VoidCallback onDone;

  const _CreateLeaveSheet({required this.service, required this.onDone});

  @override
  State<_CreateLeaveSheet> createState() => _CreateLeaveSheetState();
}

class _CreateLeaveSheetState extends State<_CreateLeaveSheet> {
  bool _isShortLeave = false;
  String _leaveType = 'annual';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _departureTime = TimeOfDay.now();
  TimeOfDay _returnTime = TimeOfDay.now();
  final _reasonCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _customTypeCtrl = TextEditingController();
  bool _trackingRequired = false;
  bool _trackingAcknowledged = false;
  bool _sending = false;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dayName(DateTime d) {
    const days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    return days[d.weekday % 7];
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (isStart) {
        _startDate = d;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = d;
      }
    });
  }

  Future<void> _pickTime(bool isDeparture) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isDeparture ? _departureTime : _returnTime,
    );
    if (t == null) return;
    setState(() {
      if (isDeparture) {
        _departureTime = t;
      } else {
        _returnTime = t;
      }
    });
  }

  Future<void> _submit() async {
    if (_isShortLeave) {
      if (_returnTime.hour < _departureTime.hour ||
          (_returnTime.hour == _departureTime.hour && _returnTime.minute <= _departureTime.minute)) {
        _snack('وقت العودة يجب أن يكون بعد المغادرة');
        return;
      }
    } else {
      if (_endDate.isBefore(_startDate)) {
        _snack('تاريخ النهاية يجب أن يكون بعد البداية');
        return;
      }
    }
    if (_sending) return;
    setState(() => _sending = true);
    try {
      if (_isShortLeave) {
        await widget.service.createShortLeave(
          leaveKind: _leaveType == 'official' ? 'official' : 'personal',
          outingDate: _startDate,
          departureTime: _fmtTime(_departureTime),
          returnTime: _fmtTime(_returnTime),
          destination: _destinationCtrl.text.isEmpty ? null : _destinationCtrl.text,
          reason: _reasonCtrl.text.isEmpty ? null : _reasonCtrl.text,
          trackingRequired: _trackingRequired,
          trackingAcknowledged: _trackingAcknowledged,
        );
      } else {
        await widget.service.createLeave(
          leaveType: _leaveType,
          startDate: _startDate,
          endDate: _endDate,
          reason: _reasonCtrl.text.isEmpty ? null : _reasonCtrl.text,
          leaveTypeCustom: _leaveType == 'other' && _customTypeCtrl.text.isNotEmpty
              ? _customTypeCtrl.text
              : null,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
      }
    } catch (e) {
      _snack('تعذر: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('طلب جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: Icon(_isShortLeave ? Icons.event_busy : Icons.exit_to_app),
                  label: Text(_isShortLeave ? 'إجازة كاملة' : 'مغادرة قصيرة'),
                  onPressed: () => setState(() => _isShortLeave = !_isShortLeave),
                ),
              ],
            ),
            const Divider(),
            if (!_isShortLeave) ..._buildFullLeaveForm() else ..._buildShortLeaveForm(),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إرسال الطلب'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFullLeaveForm() {
    return [
      const Text('نوع الإجازة', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _typeChip('annual', 'سنوية', Icons.beach_access),
          _typeChip('sick', 'مرضية', Icons.local_hospital),
          _typeChip('unpaid', 'بدون راتب', Icons.money_off),
          _typeChip('maternity', 'أمومة', Icons.pregnant_woman),
          _typeChip('paternity', 'أبوة', Icons.child_care),
          _typeChip('other', 'أخرى', Icons.more_horiz),
        ],
      ),
      if (_leaveType == 'other') ...[
        const SizedBox(height: 8),
        TextField(
          controller: _customTypeCtrl,
          decoration: const InputDecoration(
            labelText: 'اكتب نوع الإجازة',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'من تاريخ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dayName(_startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_fmtDate(_startDate)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'إلى تاريخ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dayName(_endDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_fmtDate(_endDate)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _reasonCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'السبب (اختياري)',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  List<Widget> _buildShortLeaveForm() {
    return [
      const Text('نوع المغادرة', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'official', label: Text('رسمية'), icon: Icon(Icons.flag)),
          ButtonSegment(value: 'personal', label: Text('خاصة'), icon: Icon(Icons.person)),
        ],
        selected: {_leaveType},
        onSelectionChanged: (s) => setState(() => _leaveType = s.first),
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: () => _pickDate(true),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'تاريخ المغادرة',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dayName(_startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_fmtDate(_startDate)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'ساعة المغادرة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(_fmtTime(_departureTime),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'ساعة العودة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time_filled),
                ),
                child: Text(_fmtTime(_returnTime),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _destinationCtrl,
        decoration: const InputDecoration(
          labelText: 'الوجهة (اختياري)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'السبب (اختياري)',
          border: OutlineInputBorder(),
        ),
      ),
      if (_leaveType == 'official') ...[
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('تفعيل تتبع GPS'),
          subtitle: const Text('يتطلب تفعيل تتبع الموقع خلال فترة المغادرة'),
          value: _trackingRequired,
          onChanged: (v) {
            if (v == true && !_trackingAcknowledged) {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('تأكيد تفعيل GPS'),
                  content: const Text(
                      'عند تفعيل تتبع GPS، سيتم تتبع موقعك خلال فترة المغادرة الرسمية. '
                      'هل توافق على ذلك؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () {
                        Navigator.pop(c);
                        setState(() {
                          _trackingRequired = true;
                          _trackingAcknowledged = true;
                        });
                      },
                      child: const Text('أوافق'),
                    ),
                  ],
                ),
              );
            } else {
              setState(() => _trackingRequired = v ?? false);
              if (!_trackingRequired) _trackingAcknowledged = false;
            }
          },
        ),
        if (_trackingRequired && _trackingAcknowledged)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيتم تفعيل تتبع GPS خلال المغادرة',
                    style: TextStyle(color: Colors.teal.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    ];
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final selected = _leaveType == value;
    return FilterChip(
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.primary),
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      onSelected: (_) => setState(() => _leaveType = value),
    );
  }
}
