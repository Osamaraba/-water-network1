import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../services/auth_provider.dart';
import '../../models/employee.dart';
import '../../theme/app_theme.dart';

class AdminResetPasswordScreen extends StatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  State<AdminResetPasswordScreen> createState() => _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState extends State<AdminResetPasswordScreen> {
  final AdminService _adminService = AdminService();
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  Employee? _selectedEmployee;
  bool _loading = true;
  bool _submitting = false;
  bool _showPassword = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeService.listEmployees();
      setState(() {
        _employees = employees;
        _filteredEmployees = List.from(employees);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الموظفين: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEmployees = List.from(_employees);
      } else {
        _filteredEmployees = _employees.where((e) {
          final q = query.toLowerCase();
          return e.fullName.toLowerCase().contains(q) ||
              e.employeeNumber.toLowerCase().contains(q) ||
              (e.jobTitle?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _resetPassword() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر موظفًا أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور يجب أن تكون 8 أحرف على الأقل'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمتا المرور غير متطابقتين'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await _adminService.resetPassword(
        _selectedEmployee!.employeeId,
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'تم إعادة التعيين بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedEmployee = null;
          _passwordController.clear();
          _confirmPasswordController.clear();
          _searchController.clear();
          _searchQuery = '';
          _filteredEmployees = List.from(_employees);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGM = context.watch<AuthProvider>().isGM;

    if (!isGM) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعادة تعيين كلمة المرور')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('فقط المدير العام يمكنه الوصول لهذه الصفحة', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر الموظف ثم أدخل كلمة المرور الجديدة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث بالاسم أو الرقم الوظيفي',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: _filterEmployees,
                  ),
                  const SizedBox(height: 12),

                  if (_selectedEmployee != null)
                    Card(
                      color: Colors.green.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text(_selectedEmployee!.fullName),
                        subtitle: Text('${_selectedEmployee!.employeeNumber} - ${_selectedEmployee!.jobTitle ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _selectedEmployee = null),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final emp = _filteredEmployees[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(emp.fullName[0])),
                            title: Text(emp.fullName),
                            subtitle: Text('${emp.employeeNumber} - ${emp.jobTitle ?? ''}'),
                            onTap: () => setState(() => _selectedEmployee = emp),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إعادة تعيين كلمة المرور', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
