import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _service = MaintenanceService();
  List<dynamic> _complaints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _complaints = await _service.getComplaints();
    } catch (e) {
      debugPrint('Load complaints error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _statusLabel(String s) {
    if (s == 'approved' || s == 'resolved') return 'تم الحل';
    if (s == 'rejected') return 'مرفوض';
    if (s == 'in_progress') return 'قيد التنفيذ';
    return 'قيد المراجعة';
  }

  final Map<String, String> _priorityLabels = {
    'LOW': 'منخفض',
    'NORMAL': 'عادي',
    'HIGH': 'عالٍ',
    'URGENT': 'عاجل',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('الصيانة'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showCreateDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? const Center(child: Text('لا توجد بلاغات'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final c = _complaints[index];
                    final status = c['status'] ?? '';
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.build,
                            color: c['priority'] == 'URGENT'
                                ? Colors.red
                                : Colors.brown),
                        title: Text(c['complaint_number'] ?? ''),
                        subtitle: Text(c['description'] ?? ''),
                        trailing: Chip(
                          label: Text(_statusLabel(status)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showCreateDialog() {
    final descCtrl = TextEditingController();
    String priority = 'NORMAL';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('بلاغ صيانة جديد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'الوصف', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                    labelText: 'الأولوية', border: OutlineInputBorder()),
                items: _priorityLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setModalState(() => priority = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    await _service.createComplaint(
                        description: descCtrl.text, priority: priority);
                    Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text('إرسال'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
