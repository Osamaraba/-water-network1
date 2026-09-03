import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/services.dart';
import '../../models/attendance.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _attendanceService = AttendanceService();
  final _reportService = ReportService();
  List<AttendanceRecord> _todayAttendance = [];
  DailyReport? _dailyReport;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final attendanceResult = await _attendanceService.getTodayAttendance();
      final items = attendanceResult['items'] as List? ?? [];
      _todayAttendance = items.map((e) => AttendanceRecord.fromJson(e)).toList();
      _dailyReport = await _reportService.getDailyReport();
    } catch (e) {
      debugPrint('Load profile error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _statusLabel(String s) {
    if (s == 'approved') return 'معتمدة';
    if (s == 'rejected') return 'مرفوضة';
    return 'قيد المراجعة';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملفي الشخصي'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
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
                          const CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.primary,
                              child: Icon(Icons.person, size: 48, color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(profile?.fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(profile?.jobTitle ?? '',
                              style: const TextStyle(color: Colors.grey)),
                          Text(profile?.orgUnitName ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const Divider(),
                          _infoRow('رقم الموظف', profile?.employeeNumber ?? ''),
                          _infoRow('الأدوار', profile?.roles.join(', ') ?? ''),
                          _infoRow(
                              'الصلاحيات', '${profile?.permissions.length ?? 0} صلاحية'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_todayAttendance.isNotEmpty) ...[
                    const Text('حضور اليوم',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._todayAttendance.map((a) => Card(
                          child: ListTile(
                            leading: Icon(
                                a.status == 'active'
                                    ? Icons.login
                                    : Icons.logout,
                                color: a.status == 'active'
                                    ? Colors.green
                                    : Colors.orange),
                            title: Text(a.status == 'active' ? 'دخول' : 'خروج'),
                            subtitle: Text(
                                'الدخول: ${a.checkInTime ?? "غير متوفر"}'),
                            trailing: a.checkOutTime != null
                                ? Text(
                                    'المدة: ${a.workDurationHours?.toStringAsFixed(1)} س')
                                : null,
                          ),
                        )),
                  ],
                  const SizedBox(height: 16),
                  if (_dailyReport != null) ...[
                    const Text('التقرير اليومي',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التاريخ: ${_dailyReport!.date}'),
                            Text(
                                'الدخول: ${_dailyReport!.attendance['check_in'] ?? "غير متوفر"}'),
                            Text(
                                'الخروج: ${_dailyReport!.attendance['check_out'] ?? "غير متوفر"}'),
                            Text(
                                'المدة: ${_dailyReport!.attendance['duration_hours'] ?? "غير متوفر"} ساعة'),
                            if (_dailyReport!.overtimeItems.isNotEmpty) ...[
                              const Divider(),
                              const Text('بنود العمل الإضافي:',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              ..._dailyReport!.overtimeItems.map((item) =>
                                  Text('- ${item['task']} (${_statusLabel(item['status'])})')),
                            ],
                            const Divider(),
                            Text('الموارد البشرية: ${_dailyReport!.signatures['hr_manager']}'),
                            Text('المدير العام: ${_dailyReport!.signatures['general_manager']}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
