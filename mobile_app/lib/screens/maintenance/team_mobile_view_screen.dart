import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/maintenance_team.dart';
import '../../theme/app_theme.dart';

class TeamMobileViewScreen extends StatefulWidget {
  const TeamMobileViewScreen({super.key});
  @override
  State<TeamMobileViewScreen> createState() => _TeamMobileViewScreenState();
}

class _TeamMobileViewScreenState extends State<TeamMobileViewScreen> {
  final _complaintService = TeamComplaintService();
  final _periodicService = PeriodicMaintenanceService();
  List<MaintenanceComplaint> _complaints = [];
  List<PeriodicTask> _periodicTasks = [];
  bool _loading = true;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _complaintService.getMyTeamComplaints(),
        _periodicService.getMyTeamTasks(),
      ]);
      _complaints = results[0] as List<MaintenanceComplaint>;
      _periodicTasks = results[1] as List<PeriodicTask>;
    } catch (e) {
      debugPrint('Load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'emergency':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.red;
      case 'assigned':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateComplaintStatus(MaintenanceComplaint complaint, String newStatus) async {
    try {
      await _complaintService.updateComplaint(complaint.complaintId, status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم التحديث إلى: $newStatus'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _completePeriodicTask(PeriodicTask task) async {
    final notesCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إتمام: ${task.taskName}'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ملاحظات (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, notesCtrl.text),
            child: const Text('إتمام'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await _periodicService.completeTask(task.taskId, notes: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إتمام المهمة'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مهام الفريق'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _currentTab == 0
              ? _buildComplaintsList()
              : _buildPeriodicTasksList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_complaints.length}'),
              child: const Icon(Icons.warning),
            ),
            label: 'الشكاوى',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_periodicTasks.length}'),
              child: const Icon(Icons.schedule),
            ),
            label: 'الصيانة الدورية',
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    if (_complaints.isEmpty) {
      return const Center(child: Text('لا توجد شكاوى معيّنة لفريقك'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _complaints.length,
        itemBuilder: (context, i) {
          final c = _complaints[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: _priorityColor(c.priority)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.categoryLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${c.priorityLabel} — ${c.statusLabel}',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(c.description),
                  if (c.customerName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('العميل: ${c.customerName}'),
                      ],
                    ),
                  ],
                  if (c.district != null || c.neighborhood != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${c.governorate} — ${c.district ?? ''} — ${c.neighborhood ?? ''}'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (c.status == 'assigned')
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            onPressed: () => _updateComplaintStatus(c, 'in_progress'),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('بدء التنفيذ'),
                          ),
                        ),
                      if (c.status == 'in_progress') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => _updateComplaintStatus(c, 'resolved'),
                            icon: const Icon(Icons.check),
                            label: const Text('تم الحل'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateComplaintStatus(c, 'in_progress'),
                            icon: const Icon(Icons.pause),
                            label: const Text('إيقاف مؤقت'),
                          ),
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
    );
  }

  Widget _buildPeriodicTasksList() {
    if (_periodicTasks.isEmpty) {
      return const Center(child: Text('لا توجد مهام دورية'));
    }

    final today = DateTime.now();
    final upcoming = _periodicTasks.where((t) {
      if (t.nextDue == null) return false;
      final due = DateTime.parse(t.nextDue!);
      return due.isAfter(today) && due.isBefore(today.add(const Duration(days: 7)));
    }).toList();

    final overdue = _periodicTasks.where((t) {
      if (t.nextDue == null) return false;
      final due = DateTime.parse(t.nextDue!);
      return due.isBefore(today);
    }).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (overdue.isNotEmpty) ...[
            const Text('متأخرة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
            const SizedBox(height: 8),
            ...overdue.map((t) => _buildTaskCard(t, isOverdue: true)),
            const SizedBox(height: 16),
          ],
          if (upcoming.isNotEmpty) ...[
            const Text('قادمة خلال أسبوع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
            const SizedBox(height: 8),
            ...upcoming.map((t) => _buildTaskCard(t)),
          ],
          if (overdue.isEmpty && upcoming.isEmpty)
            const Center(child: Text('لا توجد مهام قادمة خلال أسبوع')),
        ],
      ),
    );
  }

  Widget _buildTaskCard(PeriodicTask task, {bool isOverdue = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red[50] : null,
      child: ListTile(
        leading: Icon(
          isOverdue ? Icons.error : Icons.schedule,
          color: isOverdue ? Colors.red : Colors.blue,
        ),
        title: Text(task.taskName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${task.frequencyLabel} — ${task.timeOfDay}\n'
          'الاستحقاق: ${task.nextDue ?? "غير محدد"}',
        ),
        isThreeLine: true,
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => _completePeriodicTask(task),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('إتمام'),
        ),
      ),
    );
  }
}
