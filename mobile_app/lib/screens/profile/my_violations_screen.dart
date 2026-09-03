import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/violation.dart';
import '../../theme/app_theme.dart';

class MyViolationsScreen extends StatefulWidget {
  const MyViolationsScreen({super.key});
  @override
  State<MyViolationsScreen> createState() => _MyViolationsScreenState();
}

class _MyViolationsScreenState extends State<MyViolationsScreen> {
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
      _violations = await _service.getMyViolations();
    } catch (e) {
      debugPrint('load my violations error: $e');
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

  IconData _penaltyIcon(String penalty) {
    switch (penalty) {
      case 'alert1':
        return Icons.info_outline;
      case 'alert2':
        return Icons.warning_amber;
      case 'warning':
        return Icons.error_outline;
      case 'interrogation':
        return Icons.gavel;
      default:
        return Icons.warning_amber;
    }
  }

  Future<void> _acknowledge(Violation v) async {
    try {
      await _service.acknowledge(v.violationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد الاستلام'), backgroundColor: Colors.green),
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

  Future<void> _respond(Violation v) async {
    final ctrl = TextEditingController(text: v.employeeResponse);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رد على المخالفة'),
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
                      Text('النوع: ${v.violationType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('العقوبة: ${v.penaltyLabel}'),
                      Text('التاريخ: ${v.violationDate} ${v.violationTime}'),
                      if (v.notes != null && v.notes!.isNotEmpty)
                        Text('ملاحظات: ${v.notes}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'ردك / توضيحاتك',
                  border: OutlineInputBorder(),
                  hintText: 'اكتب ردك هنا...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await _service.respond(v.violationId, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال ردك'), backgroundColor: Colors.green),
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
        title: const Text('مخالفاتي'),
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
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Center(
                          child: Text('لا توجد مخالفات',
                              style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                                      _penaltyIcon(v.penalty),
                                      color: _statusColor(v.status),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.penaltyLabel,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            v.violationType,
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
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${v.violationDate} ${v.violationTime}',
                                        style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                                if (v.issuerName != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('المصدر: ${v.issuerName}',
                                          style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                ],
                                if (v.notes != null && v.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('ملاحظات: ${v.notes}'),
                                  ),
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
                                        Row(
                                          children: [
                                            const Icon(Icons.reply, size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            const Text('ردك:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(v.employeeResponse!),
                                        if (v.employeeResponseAt != null)
                                          Text('بتاريخ: ${v.employeeResponseAt}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                ],
                                if (v.hrReviewed) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                            const SizedBox(width: 4),
                                            const Text('تمت المراجعة من HR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                          ],
                                        ),
                                        if (v.hrNotes != null && v.hrNotes!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(v.hrNotes!),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (!v.acknowledged)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _acknowledge(v),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('تأكيد الاستلام'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                          ),
                                        ),
                                      ),
                                    if (!v.acknowledged) const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => _respond(v),
                                        icon: const Icon(Icons.reply, size: 16),
                                        label: Text(hasResponse ? 'تعديل الرد' : 'رد'),
                                      ),
                                    ),
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
}
