import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/maintenance_team.dart';
import '../../theme/app_theme.dart';

class PeriodicMaintenanceScreen extends StatefulWidget {
  const PeriodicMaintenanceScreen({super.key});
  @override
  State<PeriodicMaintenanceScreen> createState() => _PeriodicMaintenanceScreenState();
}

class _PeriodicMaintenanceScreenState extends State<PeriodicMaintenanceScreen> {
  final _periodicService = PeriodicMaintenanceService();
  final _teamService = TeamService();
  List<PeriodicTask> _tasks = [];
  List<MaintenanceTeam> _teams = [];
  bool _loading = true;
  String? _error;
  int? _filterTeamId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasksFuture = _periodicService.getTasks(teamId: _filterTeamId);
      final teamsFuture = _teamService.getTeams();
      
      final results = await Future.wait([tasksFuture, teamsFuture]);
      _tasks = results[0] as List<PeriodicTask>;
      _teams = results[1] as List<MaintenanceTeam>;
    } catch (e) {
      _error = 'خطأ في التحميل: $e';
      debugPrint('Load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showCreateTask() async {
    if (_teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد فرق. أنشئ فريق أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '08:00');
    int? selectedTeamId = _teams.isNotEmpty ? _teams.first.teamId : null;
    String selectedFrequency = 'weekly';
    int? selectedDayOfWeek;
    int? selectedDayOfMonth;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        String tempFrequency = selectedFrequency;
        int? tempDayOfWeek = selectedDayOfWeek;
        int? tempDayOfMonth = selectedDayOfMonth;
        
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('مهمة صيانة دورية'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedTeamId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'الفريق',
                      border: OutlineInputBorder(),
                    ),
                    items: _teams.where((t) => t.isActive).map((t) {
                      return DropdownMenuItem(
                        value: t.teamId,
                        child: Text('${t.teamName} (${t.teamTypeLabel})'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setDialogState(() => selectedTeamId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المهمة',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: فحص خطوط المياه',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tempFrequency,
                    decoration: const InputDecoration(
                      labelText: 'التكرار',
                      border: OutlineInputBorder(),
                    ),
                    items: PeriodicTask.frequencies.map((f) {
                      return DropdownMenuItem(
                        value: f['value'],
                        child: Text(f['label']!),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          tempFrequency = v;
                          selectedFrequency = v;
                        });
                      }
                    },
                  ),
                  if (tempFrequency == 'weekly' || tempFrequency == 'biweekly') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: tempDayOfWeek,
                      decoration: const InputDecoration(
                        labelText: 'اليوم',
                        border: OutlineInputBorder(),
                      ),
                      items: PeriodicTask.daysOfWeek.map((d) {
                        return DropdownMenuItem(
                          value: int.parse(d['value']!),
                          child: Text(d['label']!),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          tempDayOfWeek = v;
                          selectedDayOfWeek = v;
                        });
                      },
                    ),
                  ],
                  if (tempFrequency == 'monthly' || tempFrequency == 'quarterly') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: tempDayOfMonth,
                      decoration: const InputDecoration(
                        labelText: 'يوم الشهر',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(28, (i) => i + 1).map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text('$d'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          tempDayOfMonth = v;
                          selectedDayOfMonth = v;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الوقت (HH:MM)',
                      border: OutlineInputBorder(),
                      hintText: '08:00',
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
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('أدخل اسم المهمة')),
                    );
                    return;
                  }
                  if (selectedTeamId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('اختر الفريق')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, {
                    'team_id': selectedTeamId,
                    'task_name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    'frequency': selectedFrequency,
                    'day_of_week': selectedDayOfWeek,
                    'day_of_month': selectedDayOfMonth,
                    'time_of_day': timeCtrl.text.trim(),
                  });
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await _periodicService.createTask(
        teamId: result['team_id'],
        taskName: result['task_name'],
        description: result['description'],
        frequency: result['frequency'],
        dayOfWeek: result['day_of_week'],
        dayOfMonth: result['day_of_month'],
        timeOfDay: result['time_of_day'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء المهمة بنجاح'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showTaskHistory(PeriodicTask task) async {
    try {
      final completions = await _periodicService.getTaskCompletions(task.taskId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('سجل: ${task.taskName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: completions.isEmpty
                ? const Center(child: Text('لا يوجد سجل إتمام'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: completions.length,
                    itemBuilder: (ctx, i) {
                      final c = completions[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(c.completedDate),
                        subtitle: Text('بواسطة: ${c.employeeName ?? "غير معروف"}'),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
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
        title: const Text('الصيانة الدورية'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              setState(() => _filterTeamId = val);
              _load();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: null, child: Text('الكل')),
              ..._teams.map((t) => PopupMenuItem(
                value: t.teamId,
                child: Text(t.teamName),
              )),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _tasks.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Icon(Icons.schedule, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'لا توجد مهام دورية',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _tasks.length,
                          itemBuilder: (context, i) {
                            final task = _tasks[i];
                            final isOverdue = task.nextDue != null &&
                                DateTime.tryParse(task.nextDue!)?.isBefore(DateTime.now()) == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isOverdue ? Colors.red[50] : null,
                              child: ListTile(
                                leading: Icon(
                                  isOverdue ? Icons.error : Icons.schedule,
                                  color: isOverdue ? Colors.red : Colors.blue,
                                ),
                                title: Text(
                                  task.taskName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${task.frequencyLabel} — ${task.timeOfDay}\n'
                                  '${task.teamName ?? "فريق غير محدد"}\n'
                                  'الاستحقاق: ${task.nextDue ?? "غير محدد"}',
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (val) {
                                    if (val == 'history') _showTaskHistory(task);
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'history',
                                      child: Text('السجل'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTask,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
