import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/services.dart';
import '../../models/attendance.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});
  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  final _service = OvertimeService();
  List<OvertimeRequest> _requests = [];
  bool _loading = true;
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _isManager = Provider.of<AuthProvider>(context, listen: false).isManager;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _requests = _isManager
          ? await _service.getAllRequests()
          : await _service.getMyRequests();
    } catch (e) {
      debugPrint('Load overtime error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _statusLabel(String s) {
    if (s == 'approved') return 'معتمدة';
    if (s == 'rejected') return 'مرفوضة';
    if (s == 'completed') return 'مكتملة';
    return 'قيد المراجعة';
  }

  Color _statusColor(String s) {
    if (s == 'approved') return Colors.green;
    if (s == 'rejected') return Colors.red;
    if (s == 'completed') return Colors.blue;
    return Colors.orange;
  }

  String _workTypeLabel(String? type) {
    final labels = {'field': 'ميداني', 'office': 'مكتبي', 'maintenance': 'صيانة', 'other': 'أخرى'};
    return labels[type] ?? 'ميداني';
  }

  Future<void> _review(OvertimeRequest r, String status) async {
    final note = await showDialog<String>(
      context: context,
      builder: (c) {
        final noteCtrl = TextEditingController();
        return AlertDialog(
          title: Text(status == 'approved' ? 'تأكيد الاعتماد' : 'تأكيد الرفض'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == 'approved')
                TextField(
                  controller: TextEditingController(text: r.requestedHours.toString()),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ساعات العمل المعتمدة',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {},
                ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
      await _service.reviewRequest(r.requestId, status, note: note);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر: $e')));
      }
    }
  }

  Future<void> _extend(OvertimeRequest r) async {
    final hours = await showDialog<double>(
      context: context,
      builder: (c) {
        final ctrl = TextEditingController(text: '1');
        return AlertDialog(
          title: const Text('طلب تمديد'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد الساعات الإضافية',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, double.tryParse(ctrl.text)),
              child: const Text('تمديد'),
            ),
          ],
        );
      },
    );
    if (hours == null || hours <= 0) return;
    try {
      await _service.extendRequest(r.requestId, hours);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر: $e')));
      }
    }
  }

  Future<void> _completeTask(OvertimeRequest r) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CompleteTaskDialog(request: r, service: _service),
    );
    if (result != null) {
      _loadData();
    }
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateOvertimeSheet(service: _service, onDone: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isManager ? 'العمل الإضافي (الإدارة)' : 'العمل الإضافي'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('لا توجد طلبات عمل إضافي'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    itemBuilder: (context, i) {
                      final r = _requests[i];
                      final status = r.status;
                      final pending = status == 'pending';
                      final approved = status == 'approved';
                      final completed = status == 'completed';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    completed
                                        ? Icons.check_circle
                                        : approved
                                            ? Icons.play_circle
                                            : status == 'rejected'
                                                ? Icons.cancel
                                                : Icons.access_time,
                                    color: _statusColor(status),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.taskDescription,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${r.areaName} - ${_workTypeLabel(r.workType)}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(_statusLabel(status),
                                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                                    backgroundColor: _statusColor(status),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (_isManager && r.employeeName != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'الموظف: ${r.employeeName} (${r.employeeNumber})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  _infoChip(Icons.calendar_today, r.workDate ?? 'غير محدد'),
                                  const SizedBox(width: 8),
                                  _infoChip(Icons.access_time, '${r.requestedHours} س'),
                                  if (r.extendedHours > 0) ...[
                                    const SizedBox(width: 8),
                                    _infoChip(Icons.timer, '+${r.extendedHours} س'),
                                  ],
                                  if (r.actualHours != null) ...[
                                    const SizedBox(width: 8),
                                    _infoChip(Icons.check, '${r.actualHours} س فعلي'),
                                  ],
                                ],
                              ),
                              if (r.trackingStartsAt != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.gps_fixed, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'تتبع GPS: ${r.trackingStartsAt}',
                                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (approved && !completed)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.play_arrow, size: 18),
                                      label: const Text('إنهاء المهمة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _completeTask(r),
                                    ),
                                  if (approved && !completed) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.timer, size: 18),
                                      label: const Text('تمديد'),
                                      onPressed: () => _extend(r),
                                    ),
                                  ],
                                  if (completed)
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.print, size: 18),
                                      label: const Text('تقرير'),
                                      onPressed: () => _viewReport(r),
                                    ),
                                  if (_isManager && pending) ...[
                                    TextButton.icon(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      label: const Text('اعتماد', style: TextStyle(color: Colors.green)),
                                      onPressed: () => _review(r, 'approved'),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      label: const Text('رفض', style: TextStyle(color: Colors.red)),
                                      onPressed: () => _review(r, 'rejected'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Future<void> _viewReport(OvertimeRequest r) async {
    try {
      final printData = await _service.getPrintData(r.requestId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تقرير العمل الإضافي'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _reportRow('رقم الطلب', '${printData['request']['request_id']}'),
                _reportRow('اسم الموظف', printData['request']['employee_name'] ?? ''),
                _reportRow('رقم الموظف', printData['request']['employee_number'] ?? ''),
                _reportRow('المسمى الوظيفي', printData['request']['job_title'] ?? ''),
                _reportRow('تاريخ العمل', printData['request']['work_date'] ?? ''),
                _reportRow('نوع العمل', printData['request']['work_type'] ?? ''),
                _reportRow('المهمة', printData['request']['task_description'] ?? ''),
                _reportRow('المنطقة', printData['request']['area_name'] ?? ''),
                _reportRow('الساعات المطلوبة', '${printData['request']['requested_hours']}'),
                if (printData['request']['extended_hours'] > 0)
                  _reportRow('ساعات التمديد', '${printData['request']['extended_hours']}'),
                _reportRow('الساعات المعتمدة', '${printData['request']['total_approved_hours']}'),
                if (printData['request']['actual_hours'] != null)
                  _reportRow('الساعات الفعلية', '${printData['request']['actual_hours']}'),
                _reportRow('الحالة', _statusLabel(printData['request']['status'])),
                if (printData['request']['completed_at'] != null)
                  _reportRow('وقت الإنهاء', printData['request']['completed_at']),
                if (printData['request']['completed_lat'] != null)
                  _reportRow('إحداثيات الإنهاء', '${printData['request']['completed_lat']}, ${printData['request']['completed_lng']}'),
                if (printData['reports'] != null && (printData['reports'] as List).isNotEmpty) ...[
                  const Divider(),
                  const Text('تقارير العمل:', style: TextStyle(fontWeight: FontWeight.bold)),
                  for (var rep in printData['reports'])
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('العمل المنجز: ${rep['work_done']}'),
                          if (rep['actual_hours'] != null)
                            Text('الوقت الفعلي: ${rep['actual_hours']} ساعات'),
                          if (rep['photo_url'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Image.network(rep['photo_url'], height: 100, errorBuilder: (_, _a, _b) => const Text('صورة')),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر: $e')));
      }
    }
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}


class _CreateOvertimeSheet extends StatefulWidget {
  final OvertimeService service;
  final VoidCallback onDone;
  const _CreateOvertimeSheet({required this.service, required this.onDone});
  @override
  State<_CreateOvertimeSheet> createState() => _CreateOvertimeSheetState();
}

class _CreateOvertimeSheetState extends State<_CreateOvertimeSheet> {
  final _taskCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  String _workType = 'field';
  DateTime _workDate = DateTime.now();
  Position? _currentPosition;
  bool _sending = false;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {});
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) setState(() => _workDate = d);
  }

  Future<void> _submit() async {
    if (_taskCtrl.text.isEmpty || _areaCtrl.text.isEmpty || _hoursCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جميع الحقول مطلوبة')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await _getLocation();
      await widget.service.createRequest(
        taskDescription: _taskCtrl.text,
        areaName: _areaCtrl.text,
        areaLat: _currentPosition?.latitude ?? 31.95,
        areaLng: _currentPosition?.longitude ?? 35.91,
        requestedHours: double.tryParse(_hoursCtrl.text) ?? 1,
        workDate: _fmtDate(_workDate),
        workType: _workType,
      );
      Navigator.pop(context);
      widget.onDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر: $e')));
      }
    }
    setState(() => _sending = false);
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
          children: [
            const Text('طلب عمل إضافي جديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ العمل',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_fmtDate(_workDate)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _workType,
              decoration: const InputDecoration(
                labelText: 'نوع العمل',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'field', child: Text('ميداني')),
                DropdownMenuItem(value: 'office', child: Text('مكتبي')),
                DropdownMenuItem(value: 'maintenance', child: Text('صيانة')),
                DropdownMenuItem(value: 'other', child: Text('أخرى')),
              ],
              onChanged: (v) => setState(() => _workType = v ?? 'field'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taskCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف المهمة المطلوبة',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المنطقة / الموقع',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoursCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الساعات المطلوبة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الموقع: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إرسال الطلب'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


class _CompleteTaskDialog extends StatefulWidget {
  final OvertimeRequest request;
  final OvertimeService service;
  const _CompleteTaskDialog({required this.request, required this.service});
  @override
  State<_CompleteTaskDialog> createState() => _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends State<_CompleteTaskDialog> {
  final _workDoneCtrl = TextEditingController();
  final _picker = ImagePicker();
  Position? _currentPosition;
  File? _photo;
  bool _submitting = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {});
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 80);
    if (image != null) {
      setState(() => _photo = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (_workDoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل وصف العمل المنجز')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      double? actualHours;
      if (_startTime != null) {
        actualHours = DateTime.now().difference(_startTime!).inMinutes / 60.0;
      }

      await widget.service.completeRequest(
        widget.request.requestId,
        _workDoneCtrl.text,
        actualHours: actualHours,
        actualLat: _currentPosition?.latitude,
        actualLng: _currentPosition?.longitude,
        photoUrl: _photo?.path,
      );

      if (mounted) {
        Navigator.pop(context, {'completed': true});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنهاء المهمة بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر: $e')));
      }
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنهاء المهمة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _workDoneCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'وصف العمل المنجز',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الإحداثيات: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('تصوير الموقع'),
                onPressed: _takePhoto,
              ),
            ),
            if (_photo != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_photo!, height: 120, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('إنهاء المهمة'),
        ),
      ],
    );
  }
}
