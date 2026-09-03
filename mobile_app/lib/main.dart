import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'config/api_config.dart';
import 'services/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/leave/leave_screen.dart';
import 'screens/overtime/overtime_screen.dart';
import 'screens/maintenance/maintenance_screen.dart';
import 'screens/maintenance/maintenance_dashboard_screen.dart';
import 'screens/maintenance/teams_management_screen.dart';
import 'screens/maintenance/team_mobile_view_screen.dart';
import 'screens/maintenance/periodic_maintenance_screen.dart';
import 'screens/gps/gps_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/reports/report_inbox_screen.dart';
import 'screens/reports/report_attendance_screen.dart';
import 'screens/reports/report_leave_screen.dart';
import 'screens/reports/report_overtime_screen.dart';
import 'screens/reports/report_violations_screen.dart';
import 'screens/admin/management_reports_screen.dart';
import 'screens/admin/employee_full_profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/admin/employees_screen.dart';
import 'screens/admin/employee_import_screen.dart';
import 'screens/admin/org_structure_screen.dart';
import 'screens/admin/violation_screen.dart';
import 'screens/admin/hr_violation_review_screen.dart';
import 'screens/admin/manager_team_violations_screen.dart';
import 'screens/admin/admin_reset_password_screen.dart';
import 'screens/profile/my_violations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.load();
  runApp(const YarmoukWaterProApp());
}

class YarmoukWaterProApp extends StatelessWidget {
  const YarmoukWaterProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Yarmouk Water Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/leave': (context) => const LeaveScreen(),
          '/overtime': (context) => const OvertimeScreen(),
          '/maintenance': (context) => const MaintenanceDashboardScreen(),
          '/maintenance-dashboard': (context) => const MaintenanceDashboardScreen(),
          '/maintenance-complaints': (context) => const MaintenanceScreen(),
          '/maintenance-teams': (context) => const TeamsManagementScreen(),
          '/maintenance-team-view': (context) => const TeamMobileViewScreen(),
          '/maintenance-periodic': (context) => const PeriodicMaintenanceScreen(),
          '/gps': (context) => const GpsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/report-inbox': (context) => const ReportInboxScreen(),
          '/report-attendance': (context) => const ReportAttendanceScreen(),
          '/report-leave': (context) => const ReportLeaveScreen(),
          '/report-overtime': (context) => const ReportOvertimeScreen(),
          '/report-violations': (context) => const ReportViolationsScreen(),
          '/management-reports': (context) => const ManagementReportsScreen(),
          '/employee-full-profile': (context) => const EmployeeFullProfileScreen(),
          '/violations': (context) => const ViolationScreen(),
          '/my-violations': (context) => const MyViolationsScreen(),
          '/hr-violation-review': (context) => const HrViolationReviewScreen(),
          '/manager-team-violations': (context) => const ManagerTeamViolationsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/employees': (context) => const EmployeesScreen(),
          '/employee-import': (context) => const EmployeeImportScreen(),
          '/org-structure': (context) => const OrgStructureScreen(),
          '/admin/reset-password': (context) => const AdminResetPasswordScreen(),
        },
      ),
    );
  }
}
