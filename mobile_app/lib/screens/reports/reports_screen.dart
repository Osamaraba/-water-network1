import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/report_pdf.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = ReportService();
  Map<String, dynamic>? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      _dashboard = await _service.getDashboardReport();
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isManager = auth.isManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الإدارية'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (_dashboard != null) _buildDashboardStats(),
                  const SizedBox(height: 12),
                  _buildSection('التقارير الشخصية', [
                    _card(Icons.edit_note, 'إنشاء تقرير يومي',
                        'كتابة تقرير وإرساله إلى مديرك المباشر', () => _showCreateForm(context)),
                    _card(Icons.assessment, 'محاسبي اليومي',
                        'ملخص حضورك والعمل الإضافي اليومي', () => _showDailySummary(context)),
                  ]),
                  if (isManager) ...[
                    const SizedBox(height: 12),
                    _buildSection('التقارير الإدارية', [
                      _card(Icons.calendar_today, 'تقرير الحضور والانصراف',
                          'إحصائيات حضور الموظفين', () => Navigator.pushNamed(context, '/report-attendance')),
                      _card(Icons.beach_access, 'تقرير الإجازات',
                          'إحصائيات الإجازات للموظفين', () => Navigator.pushNamed(context, '/report-leave')),
                      _card(Icons.access_time, 'تقرير العمل الإضافي',
                          'إحصائيات العمل الإضافي', () => Navigator.pushNamed(context, '/report-overtime')),
                      _card(Icons.warning, 'تقرير المخالفات',
                          'المخالفات والجزاءات', () => Navigator.pushNamed(context, '/report-violations')),
                      _card(Icons.inbox, 'تقارير الوارد',
                          'التقارير المرسلة من الموظفين', () => Navigator.pushNamed(context, '/report-inbox')),
                    ]),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardStats() {
    return Card(
      color: AppTheme.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 إحصائيات اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('${_dashboard?['total_employees'] ?? 0}', 'الموظفين', Icons.people),
                _statItem('${_dashboard?['present_today'] ?? 0}', 'حاضرين', Icons.check_circle),
                _statItem('${_dashboard?['absent_today'] ?? 0}', 'غائبين', Icons.cancel),
                _statItem('${_dashboard?['on_leave'] ?? 0}', 'بإجازة', Icons.beach_access),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('${_dashboard?['late_arrivals'] ?? 0}', 'متأخرين', Icons.access_time),
                _statItem('${_dashboard?['overtime_pending'] ?? 0}', 'عمل إضافي', Icons.timer),
                _statItem('${_dashboard?['reports_this_week'] ?? 0}', 'التقارير', Icons.description),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _card(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showCreateForm(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تقرير يومي جديد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'التفاصيل', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await ReportService().createDailyReport(
                          title: titleCtrl.text,
                          description: descCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('تم إرسال التقرير إلى المدير'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر الإرسال: $e')));
                        }
                      }
                    },
                    child: const Text('إرسال إلى المدير'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة عبر واتساب (PDF)'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final profile = context.read<AuthProvider>().profile;
                      try {
                        await ReportPdf.share(
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          authorName: profile?.fullName ?? '',
                          authorNumber: profile?.employeeNumber ?? '',
                          date: today,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر المشاركة: $e')));
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDailySummary(BuildContext context) async {
    try {
      final report = await ReportService().getDailyReport();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('محاسبي اليومي'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('التاريخ: ${report.date}'),
                const SizedBox(height: 8),
                Text('الدخول: ${report.attendance['check_in'] ?? 'غير متوفر'}'),
                Text('الخروج: ${report.attendance['check_out'] ?? 'غير متوفر'}'),
                Text('المدة: ${report.attendance['duration_hours'] ?? 'غير متوفر'} ساعة'),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التحميل: $e')));
      }
    }
  }
}
