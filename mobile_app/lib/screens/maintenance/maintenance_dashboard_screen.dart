import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/maintenance_team.dart';
import '../../theme/app_theme.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  const MaintenanceDashboardScreen({super.key});
  @override
  State<MaintenanceDashboardScreen> createState() => _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState extends State<MaintenanceDashboardScreen> {
  final _complaintService = TeamComplaintService();
  final _teamService = TeamService();
  Map<String, dynamic>? _stats;
  List<MaintenanceComplaint> _recentComplaints = [];
  List<MaintenanceTeam> _teams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _complaintService.getStats(),
        _complaintService.getComplaints(),
        _teamService.getTeams(),
      ]);
      _stats = results[0] as Map<String, dynamic>;
      _recentComplaints = results[1] as List<MaintenanceComplaint>;
      _teams = results[2] as List<MaintenanceTeam>;
    } catch (e) {
      debugPrint('Dashboard error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الصيانة'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 16),
                  _buildTeamsStatus(),
                  const SizedBox(height: 16),
                  _buildRecentComplaints(),
                ],
              ),
            ),
      floatingActionButton: null,
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox();
    final total = _stats!['total'] ?? 0;
    final byStatus = _stats!['by_status'] as Map<String, dynamic>? ?? {};
    final byPriority = _stats!['by_priority'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('إحصائيات سريعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('الكل', '$total', Icons.list, Colors.blue),
            _statCard('جديد', '${byStatus['جديد'] ?? 0}', Icons.fiber_new, Colors.red),
            _statCard('قيد التنفيذ', '${byStatus['قيد التنفيذ'] ?? 0}', Icons.pending, Colors.orange),
            _statCard('تم الحل', '${byStatus['تم الحل'] ?? 0}', Icons.check_circle, Colors.green),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('طارئ', '${byPriority['طارئ'] ?? 0}', Icons.warning, Colors.red),
            _statCard('مرتفع', '${byPriority['مرتفع'] ?? 0}', Icons.arrow_upward, Colors.orange),
            _statCard('متوسط', '${byPriority['متوسط'] ?? 0}', Icons.remove, Colors.blue),
            _statCard('منخفض', '${byPriority['منخفض'] ?? 0}', Icons.arrow_downward, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('حالة الفرق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (_teams.isEmpty)
          const Text('لا توجد فرق مسجلة')
        else
          ..._teams.map((team) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Text('${team.memberCount}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(team.teamName),
              subtitle: Text('${team.teamTypeLabel} — ${team.governorate}'),
              trailing: Icon(
                team.isActive ? Icons.check_circle : Icons.cancel,
                color: team.isActive ? Colors.green : Colors.red,
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildRecentComplaints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('آخر الشكاوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/maintenance-complaints'),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentComplaints.isEmpty)
          const Text('لا توجد شكاوى')
        else
          ..._recentComplaints.take(5).map((c) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.warning,
                color: _priorityColor(c.priority),
              ),
              title: Text(c.categoryLabel),
              subtitle: Text(
                '${c.description}\n${c.governorate} — ${c.statusLabel}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(c.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor(c.status)),
                ),
                child: Text(c.statusLabel, style: TextStyle(color: _statusColor(c.status), fontSize: 11)),
              ),
            ),
          )),
      ],
    );
  }
}
