import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/violation.dart';
import '../../theme/app_theme.dart';

class ManagerTeamViolationsScreen extends StatefulWidget {
  const ManagerTeamViolationsScreen({super.key});
  @override
  State<ManagerTeamViolationsScreen> createState() => _ManagerTeamViolationsScreenState();
}

class _ManagerTeamViolationsScreenState extends State<ManagerTeamViolationsScreen> {
  final _service = ViolationService();
  List<Violation> _violations = [];
  bool _loading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _violations = await _service.getTeamViolations(status: _filterStatus);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مخالفات فريقي'),
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
        ],
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
                          child: Text('لا توجد مخالفات صادرة منك',
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
                                            v.employeeName ?? "موظف #${v.employeeId}",
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
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${v.violationDate} ${v.violationTime}',
                                        style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
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
                                        Row(
                                          children: [
                                            const Icon(Icons.reply, size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            const Text('رد الموظف:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                                            const Text('مراجعة HR:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                          ],
                                        ),
                                        if (v.hrNotes != null && v.hrNotes!.isNotEmpty)
                                          Text(v.hrNotes!),
                                      ],
                                    ),
                                  ),
                                ],
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
