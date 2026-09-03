import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/maintenance_team.dart';
import '../../models/employee.dart';
import '../../theme/app_theme.dart';

class TeamsManagementScreen extends StatefulWidget {
  const TeamsManagementScreen({super.key});
  @override
  State<TeamsManagementScreen> createState() => _TeamsManagementScreenState();
}

class _TeamsManagementScreenState extends State<TeamsManagementScreen> {
  final _teamService = TeamService();
  final _employeeService = EmployeeService();
  List<MaintenanceTeam> _teams = [];
  List<Employee> _employees = [];
  bool _loading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _teamService.getTeams(teamType: _filterType),
        _employeeService.listEmployees(),
      ]);
      _teams = results[0] as List<MaintenanceTeam>;
      _employees = results[1] as List<Employee>;
    } catch (e) {
      debugPrint('Load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showCreateTeam() async {
    final nameCtrl = TextEditingController();
    String selectedType = 'water_maintenance';
    String selectedGov = 'عمّان';
    int? selectedLeader;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إنشاء فريق جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الفريق', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'نوع الفريق', border: OutlineInputBorder()),
                  items: MaintenanceTeam.teamTypes
                      .map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGov,
                  decoration: const InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder()),
                  items: MaintenanceComplaint.governorates
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedGov = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedLeader,
                  decoration: const InputDecoration(labelText: 'قائد الفريق (اختياري)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون قائد')),
                    ..._employees.map((e) => DropdownMenuItem(
                        value: e.employeeId, child: Text('${e.fullName} (${e.employeeNumber})'))),
                  ],
                  onChanged: (v) {
                    setDialogState(() => selectedLeader = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                Navigator.pop(ctx, {
                  'team_name': nameCtrl.text,
                  'team_type': selectedType,
                  'governorate': selectedGov,
                  'team_leader_id': selectedLeader,
                });
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      await _teamService.createTeam(
        teamName: result['team_name'],
        teamType: result['team_type'],
        governorate: result['governorate'],
        teamLeaderId: result['team_leader_id'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الفريق'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _showTeamDetails(MaintenanceTeam team) async {
    try {
      final fullTeam = await _teamService.getTeam(team.teamId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(team.teamName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow('النوع', team.teamTypeLabel),
                _infoRow('المحافظة', team.governorate),
                _infoRow('قائد الفريق', team.leaderName ?? 'غير محدد'),
                _infoRow('عدد الأعضاء', '${fullTeam.members?.length ?? 0}'),
                _infoRow('الحد الأقصى للمهام', '${team.maxActiveTasks}'),
                const Divider(),
                const Text('أعضاء الفريق:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (fullTeam.members != null && fullTeam.members!.isEmpty)
                  const Text('لا يوجد أعضاء')
                else
                  ...(fullTeam.members ?? []).map((m) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person),
                        title: Text(m.employeeName),
                        subtitle: Text('${m.employeeNumber} — ${m.role}'),
                      )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddMember(team);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة عضو'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showAddMember(MaintenanceTeam team) async {
    int? selectedEmployee;
    String role = 'technician';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('إضافة عضو لـ ${team.teamName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedEmployee,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'الموظف', border: OutlineInputBorder()),
                items: _employees
                    .where((e) => !(team.members?.any((m) => m.employeeId == e.employeeId) ?? false))
                    .map((e) => DropdownMenuItem(
                        value: e.employeeId, child: Text('${e.fullName} (${e.employeeNumber})')))
                    .toList(),
                onChanged: (v) {
                  setDialogState(() => selectedEmployee = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'الدور', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'technician', child: Text('فني')),
                  DropdownMenuItem(value: 'driver', child: Text('سائق')),
                  DropdownMenuItem(value: 'leader', child: Text('قائد')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => role = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () {
                if (selectedEmployee == null) return;
                Navigator.pop(ctx, {'employee_id': selectedEmployee, 'role': role});
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      await _teamService.addMember(team.teamId, result['employee_id'], role: result['role']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة العضو'), backgroundColor: Colors.green),
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
        title: const Text('إدارة الفرق'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              setState(() => _filterType = val);
              _load();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: null, child: Text('الكل')),
              ...MaintenanceTeam.teamTypes
                  .map((t) => PopupMenuItem(value: t['value'], child: Text(t['label']!))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _teams.isEmpty
                  ? const Center(child: Text('لا توجد فرق'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _teams.length,
                      itemBuilder: (context, i) {
                        final team = _teams[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Text('${team.memberCount}', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(team.teamName),
                            subtitle: Text('${team.teamTypeLabel}\n${team.governorate}'),
                            isThreeLine: true,
                            trailing: Icon(
                              team.isActive ? Icons.check_circle : Icons.cancel,
                              color: team.isActive ? Colors.green : Colors.red,
                            ),
                            onTap: () => _showTeamDetails(team),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTeam,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
