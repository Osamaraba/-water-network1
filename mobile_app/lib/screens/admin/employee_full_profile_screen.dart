import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EmployeeFullProfileScreen extends StatefulWidget {
  const EmployeeFullProfileScreen({super.key});

  @override
  State<EmployeeFullProfileScreen> createState() => _EmployeeFullProfileScreenState();
}

class _EmployeeFullProfileScreenState extends State<EmployeeFullProfileScreen> {
  bool _loading = true;
  Map<String, dynamic> _profileData = {};
  String _error = '';
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      _employeeId = args is int ? args : null;
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (_employeeId == null) {
      final auth = context.read<AuthProvider>();
      _employeeId = auth.profile?.employeeId;
    }
    if (_employeeId == null) {
      setState(() {
        _loading = false;
        _error = 'لا يمكن تحديد الموظف';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await apiService.get('/reports-extended/full-profile/$_employeeId');
      if (result.containsKey('error')) {
        setState(() {
          _loading = false;
          _error = result['error'];
        });
      } else {
        setState(() {
          _profileData = result;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading employee profile: $e');
      setState(() {
        _loading = false;
        _error = 'فشل تحميل البيانات: $e';
      });
    }
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'غير متوفر',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الكامل للموظف'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('محاولة مرة أخرى'),
                        ),
                      ],
                    ),
                  ),
                )
              : _profileData.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات متاحة',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            'البيانات الشخصية',
                            Column(
                              children: [
                                _buildInfoRow(
                                  'الاسم الكامل',
                                  _profileData['full_name'] ?? '',
                                  isBold: true,
                                ),
                                _buildInfoRow(
                                  'رقم الموظف',
                                  _profileData['employee_number']?.toString() ?? '',
                                ),
                                _buildInfoRow('الوظيفة', _profileData['job_title'] ?? ''),
                                _buildInfoRow('الوحدة', _profileData['org_unit_name'] ?? ''),
                                _buildInfoRow('البريد', _profileData['email'] ?? ''),
                                _buildInfoRow('الهاتف', _profileData['phone'] ?? ''),
                                _buildInfoRow(
                                  'الحالة',
                                  _profileData['is_active'] == true ? 'نشط' : 'غير نشط',
                                ),
                                _buildInfoRow('تاريخ التعيين', _profileData['hire_date']?.toString() ?? ''),
                              ],
                            ),
                          ),
                          _buildSection(
                            'الحضور والغياب (آخر 30 يوم)',
                            _profileData['attendance_summary'] != null
                                ? _buildAttendanceSummary(_profileData['attendance_summary'])
                                : const Center(child: Text('لا توجد بيانات حضور')),
                          ),
                          _buildSection(
                            'الإجازات',
                            _profileData['leave_summary'] != null
                                ? _buildLeaveSummary(_profileData['leave_summary'])
                                : const Center(child: Text('لا توجد بيانات إجازات')),
                          ),
                          _buildSection(
                            'العمل الإضافي',
                            _profileData['overtime_summary'] != null
                                ? _buildOvertimeSummary(_profileData['overtime_summary'])
                                : const Center(child: Text('لا توجد بيانات عمل إضافي')),
                          ),
                          _buildSection(
                            'المخالفات',
                            _profileData['violation_summary'] != null
                                ? _buildViolationSummary(_profileData['violation_summary'])
                                : const Center(child: Text('لا توجد مخالفات')),
                          ),
                          _buildSection(
                            'التتبع والموقع',
                            _profileData['gps_summary'] != null
                                ? _buildGpsSummary(_profileData['gps_summary'])
                                : const Center(child: Text('لا توجد بيانات تتبع')),
                          ),
                          _buildSection(
                            'التوزيع والصيانة',
                            _profileData['work_summary'] != null
                                ? _buildWorkSummary(_profileData['work_summary'])
                                : const Center(child: Text('لا توجد بيانات عمل')),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildAttendanceSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow('أيام الحضور', data['present_days']?.toString() ?? '0'),
        _buildInfoRow('أيام الغياب', data['absent_days']?.toString() ?? '0'),
        _buildInfoRow('أيام التأخير', data['late_days']?.toString() ?? '0'),
        _buildInfoRow('ساعات العمل الإجمالية', '${data['total_hours']?.toStringAsFixed(1)} س'),
        _buildInfoRow('متوسط الساعات اليومية', '${data['avg_daily_hours']?.toStringAsFixed(1)} س'),
      ],
    );
  }

  Widget _buildLeaveSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow('إجازات مرضية', data['sick_leave']?.toString() ?? '0'),
        _buildInfoRow('إجازات عادية', data['regular_leave']?.toString() ?? '0'),
        _buildInfoRow('إجازات طارئة', data['emergency_leave']?.toString() ?? '0'),
        _buildInfoRow('إجازات مستحقة', data['accrued_leave']?.toString() ?? '0'),
        _buildInfoRow('إجازات المستخدمة', data['used_leave']?.toString() ?? '0'),
      ],
    );
  }

  Widget _buildOvertimeSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow('طلبات العمل الإضافي', data['request_count']?.toString() ?? '0'),
        _buildInfoRow('ساعات المطلوبة', '${data['requested_hours']?.toStringAsFixed(1)} س'),
        _buildInfoRow('ساعات معتمدة', '${data['approved_hours']?.toStringAsFixed(1)} س'),
        _buildInfoRow('ساعات منفذة', '${data['completed_hours']?.toStringAsFixed(1)} س'),
        _buildInfoRow('متوسط الساعات/طلب', '${data['avg_hours_per_request']?.toStringAsFixed(1)} س'),
      ],
    );
  }

  Widget _buildViolationSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow('عدد المخالفات', data['total_count']?.toString() ?? '0'),
        _buildInfoRow('مخالفات نشطة', data['active_count']?.toString() ?? '0'),
        _buildInfoRow('مخالفات مسجّلة', data['recorded_count']?.toString() ?? '0'),
        if (data['latest_violation'] != null)
          _buildInfoRow(
            'آخر مخالفة',
            '${data['latest_violation']['type']} - ${data['latest_violation']['date']}',
          ),
      ],
    );
  }

  Widget _buildGpsSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow('إجمالي الجلسات', data['total_sessions']?.toString() ?? '0'),
        _buildInfoRow('ساعات التتبع', '${data['tracked_hours']?.toStringAsFixed(1)} س'),
        _buildInfoRow('المسافة المقطوعة', '${data['total_distance_km']?.toStringAsFixed(1)} كم'),
        _buildInfoRow('عدد الخروقات', data['breach_count']?.toString() ?? '0'),
        _buildInfoRow('وقت خارج النطاق', '${data['outside_duration_min']?.toStringAsFixed(1)} د'),
      ],
    );
  }

  Widget _buildWorkSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow('طلبات الصيانة', data['maintenance_requests']?.toString() ?? '0'),
        _buildInfoRow('طلبات التوزيع', data['distribution_requests']?.toString() ?? '0'),
        _buildInfoRow('شكاوى العملاء', data['customer_complaints']?.toString() ?? '0'),
                                _buildInfoRow('إنجازات الصيانة', data['maintenance_completed']?.toString() ?? '0'),
        _buildInfoRow('مكالمات تم الرد عليها', data['calls_handled']?.toString() ?? '0'),
      ],
    );
  }
}