import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/services.dart';
import '../../models/employee.dart';
import '../../models/org.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeService _service = EmployeeService();
  final TextEditingController _searchController = TextEditingController();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  List<RoleItem> _roles = [];
  List<WorkTypeItem> _workTypes = [];
  List<OrgUnit> _units = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredEmployees = List.from(_employees);
      } else {
        _filteredEmployees = _employees.where((e) {
          final query = _searchQuery.toLowerCase();
          return e.fullName.toLowerCase().contains(query) ||
              e.employeeNumber.toLowerCase().contains(query) ||
              (e.jobTitle?.toLowerCase().contains(query) ?? false) ||
              (e.orgUnitName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  List<DropdownMenuItem<int>> _buildManagerItems() {
    // Group employees by org unit
    Map<String, List<Employee>> grouped = {};
    for (var emp in _employees) {
      final unitName = emp.orgUnitName ?? 'بدون وحدة';
      if (!grouped.containsKey(unitName)) {
        grouped[unitName] = [];
      }
      grouped[unitName]!.add(emp);
    }
    
    List<DropdownMenuItem<int>> items = [];
    
    // Add "no manager" option
    items.add(const DropdownMenuItem(
      value: null,
      child: Text('بدون مدير', style: TextStyle(color: Colors.grey)),
    ));
    
    // Add employees grouped by unit
    grouped.forEach((unitName, employees) {
      // Add unit header
      items.add(DropdownMenuItem(
        value: -1, // Invalid value to act as header
        enabled: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Text(
            unitName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
              fontSize: 12,
            ),
          ),
        ),
      ));
      
      // Add employees in this unit
      for (var emp in employees) {
        items.add(DropdownMenuItem(
          value: emp.employeeId,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    emp.fullName[0],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.fullName,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        emp.employeeNumber,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
      }
    });
    
    return items;
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.listEmployees(),
        _service.listRoles(),
        _service.listWorkTypes(),
        OrgService().getOrgUnits(),
      ]);
      _employees = results[0] as List<Employee>;
      _filteredEmployees = List.from(_employees);
      _roles = results[1] as List<RoleItem>;
      _workTypes = results[2] as List<WorkTypeItem>;
      _units = results[3] as List<OrgUnit>;
    } catch (e) {
      debugPrint('Load employees error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Employee e, {bool hard = false}) async {
    final action = hard ? 'حذف نهائي' : 'تعطيل';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('تأكيد $action'),
        content: Text(hard
            ? 'سيتم حذف الموظف ${e.fullName} نهائياً مع كل صلاحياته. لا يمكن التراجع.\nهل أنت متأكد؟'
            : 'هل تريد تعطيل الموظف ${e.fullName}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(action, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (hard) {
        await _service.hardDeleteEmployee(e.employeeId);
      } else {
        await _service.deleteEmployee(e.employeeId);
      }
      _loadData();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر: $err')));
      }
    }
  }

  void _showForm({Employee? emp}) {
    final numberCtrl = TextEditingController(text: emp?.employeeNumber ?? '');
    final nameCtrl = TextEditingController(text: emp?.fullName ?? '');
    final titleCtrl = TextEditingController(text: emp?.jobTitle ?? '');
    final phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    final emailCtrl = TextEditingController(text: emp?.email ?? '');
    final passCtrl = TextEditingController();
    String? selectedRole = emp == null ? null : _roleFor(emp);
    int? selectedUnit = emp?.orgUnitId;
    int? selectedWork = emp?.workTypeId;
    int? selectedManager = emp?.directManagerId;
    bool fieldTracking = emp?.allowFieldTracking ?? false;
    final latCtrl = TextEditingController(text: emp?.geofenceLat?.toString() ?? '');
    final lngCtrl = TextEditingController(text: emp?.geofenceLng?.toString() ?? '');
    final radiusCtrl = TextEditingController(text: (emp?.geofenceRadiusM ?? 200).toString());
    bool geofenceExempt = emp?.geofenceExempt ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emp == null ? 'موظف جديد' : 'تعديل موظف',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                    controller: numberCtrl,
                    decoration: const InputDecoration(labelText: 'رقم الموظف', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'المسمى الوظيفي', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'البريد', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  hint: const Text('الدور'),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r.roleName, child: Text(r.roleLabel)))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedRole = v),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedUnit,
                  hint: const Text('الوحدة التنظيمية'),
                  items: _units
                      .map((u) => DropdownMenuItem(value: u.orgUnitId, child: Text(u.unitName)))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedUnit = v),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedWork,
                  hint: const Text('نوع العمل'),
                  items: _workTypes
                      .map((w) => DropdownMenuItem(value: w.workTypeId, child: Text(w.typeNameAr)))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedWork = v),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedManager,
                  hint: const Text('المدير المباشر'),
                  items: _buildManagerItems(),
                  onChanged: (v) => setModal(() => selectedManager = v),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.person_search),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: emp == null ? 'كلمة المرور' : 'كلمة مرور جديدة (اختياري)',
                        border: const OutlineInputBorder())),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('يسمح بتتبع الموقع الميداني'),
                  value: fieldTracking,
                  onChanged: (v) => setModal(() => fieldTracking = v ?? false),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const Text('نطاق موقع العمل (التقييد الجغرافي)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'خط العرض (Latitude)', border: OutlineInputBorder())),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                          controller: lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'خط الطول (Longitude)', border: OutlineInputBorder())),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location, color: Colors.green),
                    label: const Text('جلب الإحداثيات الحالية'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    onPressed: () async {
                      try {
                        LocationPermission permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }
                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يجب السماح بالوصول للموقع')),
                            );
                          }
                          return;
                        }
                        final pos = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high);
                        setModal(() {
                          latCtrl.text = pos.latitude.toStringAsFixed(6);
                          lngCtrl.text = pos.longitude.toStringAsFixed(6);
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم جلب الموقع: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ في جلب الموقع: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: radiusCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'نصف القطر المسموح بالمتر (مثال 200)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('إعفاء من التقييد (موظف ميداني يعمل خارج المركز)'),
                  value: geofenceExempt,
                  onChanged: (v) => setModal(() => geofenceExempt = v ?? false),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (numberCtrl.text.isEmpty || nameCtrl.text.isEmpty || selectedRole == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('رقم الموظف والاسم والدور مطلوبة')));
                        return;
                      }
                      final body = <String, dynamic>{
                        'employee_number': numberCtrl.text,
                        'full_name': nameCtrl.text,
                        'job_title': titleCtrl.text,
                        'phone': phoneCtrl.text,
                        'email': emailCtrl.text,
                        'role': selectedRole,
                        'org_unit_id': selectedUnit,
                        'work_type_id': selectedWork,
                        'direct_manager_id': selectedManager,
                        'allow_field_tracking': fieldTracking,
                        'geofence_lat': latCtrl.text.isEmpty ? null : double.parse(latCtrl.text),
                        'geofence_lng': lngCtrl.text.isEmpty ? null : double.parse(lngCtrl.text),
                        'geofence_radius_m': int.tryParse(radiusCtrl.text) ?? 200,
                        'geofence_exempt': geofenceExempt,
                      };
                      try {
                        if (emp == null) {
                          if (passCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('كلمة المرور مطلوبة')));
                            return;
                          }
                          body['password'] = passCtrl.text;
                          await _service.createEmployee(body);
                        } else {
                          if (passCtrl.text.isNotEmpty) body['new_password'] = passCtrl.text;
                          await _service.updateEmployee(emp.employeeId, body);
                        }
                        Navigator.pop(ctx);
                        _loadData();
                      } catch (err) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('تعذر الحفظ: $err')));
                      }
                    },
                    child: const Text('حفظ'),
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

  String? _roleFor(Employee e) {
    return e.primaryRole;
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthProvider>().hasPermission('employees.manage');
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (canManage) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download, color: Colors.white),
              tooltip: 'تنزيل قالب',
              onSelected: (v) async {
                final service = EmployeeService();
                try {
                  final bytes = await service.downloadTemplateBytes(dynamic: v == 'dynamic');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      'تم تنزيل ${bytes.length} بايت — القالب سيفتح تلقائياً',
                    )),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
                }
              },
              itemBuilder: (c) => [
                const PopupMenuItem(
                  value: 'dynamic',
                  child: Row(children: [
                    Icon(Icons.dynamic_feed, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('قالب ديناميكي (مُفلتر)'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'static',
                  child: Row(children: [
                    Icon(Icons.file_copy, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('قالب ثابت (فارغ)'),
                  ]),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              tooltip: 'استيراد Excel',
              onPressed: () {
                Navigator.pushNamed(context, '/employee-import');
              },
            ),
          ],
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showForm(),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث عن موظف',
                      hintText: 'اسم الموظف، الرقم، المسمى الوظيفي...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _filterEmployees();
                                });
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterEmployees();
                      });
                    },
                  ),
                ),
                // Employee Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'عدد الموظفين: ${_filteredEmployees.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          'نتائج البحث: ${_filteredEmployees.length}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Employee List
                Expanded(
                  child: _filteredEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'لا توجد نتائج للبحث عن "$_searchQuery"'
                                    : 'لا يوجد موظفون',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, i) {
                            final e = _filteredEmployees[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  child: Text(
                                    e.fullName[0],
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  e.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الرقم: ${e.employeeNumber}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    if (e.jobTitle != null && e.jobTitle!.isNotEmpty)
                                      Text(
                                        'المسمى: ${e.jobTitle}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    if (e.orgUnitName != null && e.orgUnitName!.isNotEmpty)
                                      Text(
                                        'الوحدة: ${e.orgUnitName}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.person_search, color: Colors.teal),
                                      tooltip: 'الملف الكامل',
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/employee-full-profile',
                                          arguments: e.employeeId,
                                        );
                                      },
                                    ),
                                    if (canManage) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'تعديل',
                                        onPressed: () => _showForm(emp: e),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'حذف',
                                        onSelected: (v) => _delete(e, hard: v == 'hard'),
                                        itemBuilder: (c) => [
                                          const PopupMenuItem(
                                            value: 'soft',
                                            child: Row(children: [
                                              Icon(Icons.delete_outline, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('تعطيل (إبقاء السجل)'),
                                            ]),
                                          ),
                                          const PopupMenuItem(
                                            value: 'hard',
                                            child: Row(children: [
                                              Icon(Icons.delete_forever, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('حذف نهائي'),
                                            ]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
