import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _pendingLeaves;
  int? _pendingOvertime;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isManager) return;
    try {
      final leaves = await LeaveService().getAllLeaves(status: 'pending');
      final overtime = await OvertimeService().getAllRequests(status: 'pending');
      if (mounted) {
        setState(() {
          _pendingLeaves = leaves.length;
          _pendingOvertime = overtime.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yarmouk Water Pro'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.pushNamed(context, '/notifications')
                    .then((_) => _loadCounts()),
              ),
              if (auth.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      auth.unreadCount > 9 ? '9+' : '${auth.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: const Icon(Icons.person, size: 36, color: Colors.white)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile?.fullName ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(profile?.jobTitle ?? '',
                              style: const TextStyle(color: Colors.white70)),
                          Text(profile?.orgUnitName ?? '',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('إجراءات سريعة',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildTile(context, Icons.login, 'تسجيل دخول', Colors.green, () => Navigator.pushNamed(context, '/attendance')),
                _buildTile(context, Icons.logout, 'تسجيل خروج', Colors.orange, () => Navigator.pushNamed(context, '/attendance')),
                _buildTile(context, Icons.event_busy, 'إجازة', Colors.red,
                    () => Navigator.pushNamed(context, '/leave').then((_) => _loadCounts()),
                    badge: _pendingLeaves),
                _buildTile(context, Icons.access_time, 'عمل إضافي', Colors.purple,
                    () => Navigator.pushNamed(context, '/overtime').then((_) => _loadCounts()),
                    badge: _pendingOvertime),
                _buildTile(context, Icons.build, 'لوحة الصيانة', Colors.brown, () => Navigator.pushNamed(context, '/maintenance')),
                _buildTile(context, Icons.gps_fixed, 'تحديد الموقع', Colors.teal, () => Navigator.pushNamed(context, '/gps')),
                _buildTile(context, Icons.assessment, 'تقارير', Colors.indigo, () => Navigator.pushNamed(context, '/reports')),
                _buildTile(context, Icons.notifications, 'إشعارات',
                    auth.unreadCount > 0 ? Colors.red : Colors.blueGrey,
                    () => Navigator.pushNamed(context, '/notifications').then((_) => _loadCounts())),
                _buildTile(context, Icons.person, 'الملف الشخصي', Colors.blue, () => Navigator.pushNamed(context, '/profile')),
                _buildTile(context, Icons.report, 'مخالفاتي', Colors.red.shade700,
                    () => Navigator.pushNamed(context, '/my-violations')),
                _buildTile(context, Icons.engineering, 'مهام فريقي', Colors.cyan.shade700,
                    () => Navigator.pushNamed(context, '/maintenance-team-view')),
                if (auth.hasPermission('employees.manage')) ...[
                  _buildTile(context, Icons.group, 'الموظفون', Colors.cyan,
                      () => Navigator.pushNamed(context, '/employees')),
                  _buildTile(context, Icons.account_tree, 'الهيكل التنظيمي', Colors.deepPurple,
                      () => Navigator.pushNamed(context, '/org-structure')),
                ],
                if (auth.isManager) ...[
                  _buildTile(context, Icons.warning, 'إصدار مخالفة', Colors.orange,
                      () => Navigator.pushNamed(context, '/violations')),
                  _buildTile(context, Icons.analytics, 'تقارير إدارية', Colors.indigo,
                      () => Navigator.pushNamed(context, '/management-reports')),
                  _buildTile(context, Icons.groups, 'إدارة الفرق', Colors.teal.shade700,
                      () => Navigator.pushNamed(context, '/maintenance-teams')),
                  _buildTile(context, Icons.schedule, 'الصيانة الدورية', Colors.blue.shade700,
                      () => Navigator.pushNamed(context, '/maintenance-periodic')),
                ],
                if (auth.hasPermission('employees.manage'))
                  _buildTile(context, Icons.person_search, 'الملف الكامل', Colors.teal,
                      () => Navigator.pushNamed(context, '/employee-full-profile')),
                if (auth.isGM)
                  _buildTile(context, Icons.lock_reset, 'إعادة تعيين كلمة المرور', Colors.red.shade700,
                      () => Navigator.pushNamed(context, '/admin/reset-password')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap,
      {int? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.18))),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(height: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ],
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
