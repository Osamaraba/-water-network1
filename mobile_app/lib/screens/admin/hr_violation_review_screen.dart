import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/violation.dart';
import '../../theme/app_theme.dart';

class HrViolationReviewScreen extends StatefulWidget {
  const HrViolationReviewScreen({super.key});
  @override
  State<HrViolationReviewScreen> createState() => _HrViolationReviewScreenState();
}

class _HrViolationReviewScreenState extends State<HrViolationReviewScreen> {
  final _service = ViolationService();
  List<Violation> _violations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _violations = await _service.getPendingReview();
    } catch (e) {
      debugPrint('Load error: $e');
    }
    if (mounted) setState(() => _loading = false);
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

  Future<void> _reviewViolation(Violation v) async {
    final notesCtrl = TextEditingController();
    String selectedStatus = 'reviewed';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('مراجعة مخالفة #${v.violationId}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الموظف: ${v.employeeName ?? "غير معروف"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('نوع المخالفة: ${v.violationType}'),
                        Text('العقوبة: ${v.penaltyLabel}'),
                        Text('التاريخ: ${v.violationDate} ${v.violationTime}'),
                        if (v.notes != null && v.notes!.isNotEmpty)
                          Text('ملاحظات المدير: ${v.notes}'),
                      ],
                    ),
                  ),
                ),
                if (v.employeeResponse != null && v.employeeResponse!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('رد الموظف:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 4),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(v.employeeResponse!),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('القرار:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: Violation.statusOptions
                      .where((o) => ['reviewed', 'closed'].contains(o['value']))
                      .map((o) => DropdownMenuItem(
                          value: o['value'], child: Text(o['label']!)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات HR',
                    border: OutlineInputBorder(),
                    hintText: 'أضف ملاحظاتك هنا...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, {
                'hr_notes': notesCtrl.text,
                'status': selectedStatus,
              }),
              child: const Text('تأكيد المراجعة'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      await _service.hrReview(
        v.violationId,
        hrNotes: result['hr_notes']!,
        status: result['status']!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت مراجعة المخالفة بنجاح'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة المخالفات (HR)'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _violations.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text('لا توجد مخالفات قيد المراجعة',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _violations.length,
                      itemBuilder: (context, i) {
                        final v = _violations[i];
                        final hasResponse = v.employeeResponse != null && v.employeeResponse!.isNotEmpty;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      hasResponse ? Icons.reply : Icons.warning_amber,
                                      color: hasResponse ? Colors.blue : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${v.employeeName ?? "موظف #${v.employeeId}"}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            '${v.penaltyLabel} — ${v.violationType}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(v.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _statusColor(v.status)),
                                      ),
                                      child: Text(
                                        v.statusLabel,
                                        style: TextStyle(color: _statusColor(v.status), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Text('المصدر: ${v.issuerName ?? "غير معروف"}'),
                                Text('التاريخ: ${v.violationDate} ${v.violationTime}'),
                                if (v.notes != null && v.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('ملاحظات: ${v.notes}'),
                                ],
                                if (hasResponse) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('رد الموظف:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                        const SizedBox(height: 4),
                                        Text(v.employeeResponse!),
                                        if (v.employeeResponseAt != null)
                                          Text('بتاريخ: ${v.employeeResponseAt}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => _reviewViolation(v),
                                    icon: const Icon(Icons.gavel),
                                    label: const Text('مراجعة واتخاذ قرار'),
                                  ),
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
}
