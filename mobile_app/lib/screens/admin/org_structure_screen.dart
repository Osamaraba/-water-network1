import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../models/org.dart';
import '../../theme/app_theme.dart';

class OrgStructureScreen extends StatefulWidget {
  const OrgStructureScreen({super.key});
  @override
  State<OrgStructureScreen> createState() => _OrgStructureScreenState();
}

class _OrgStructureScreenState extends State<OrgStructureScreen> {
  final OrgService _orgService = OrgService();
  List<Map<String, dynamic>> _orgTree = [];
  List<OrgUnit> _flatUnits = [];
  bool _loading = true;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _loadOrgTree();
  }

  Future<void> _loadOrgTree() async {
    setState(() => _loading = true);
    try {
      final tree = await _orgService.getOrgTree();
      _orgTree = List<Map<String, dynamic>>.from(tree);
      final units = await _orgService.getOrgUnits();
      _flatUnits = units;
    } catch (e) {
      debugPrint('Load org tree error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showAddUnitDialog({int? parentId}) {
    final nameCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String hierarchyLevel = 'SECTION';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة وحدة تنظيمية'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الوحدة (عربي)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الوحدة (إنجليزي)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'كود الوحدة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: hierarchyLevel,
                  decoration: const InputDecoration(
                    labelText: 'مستوى الهيكل',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DIRECTORATE', child: Text('مديرية')),
                    DropdownMenuItem(value: 'DEPARTMENT', child: Text('قسم')),
                    DropdownMenuItem(value: 'SECTION', child: Text('شعبة')),
                  ],
                  onChanged: (v) => setDialogState(() => hierarchyLevel = v ?? 'SECTION'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الاسم والكود مطلوبان')),
                  );
                  return;
                }
                try {
                  await _orgService.createUnit({
                    'unit_name': nameCtrl.text,
                    'unit_name_en': nameEnCtrl.text,
                    'unit_code': codeCtrl.text,
                    'hierarchy_level': hierarchyLevel,
                    'parent_id': parentId,
                  });
                  Navigator.pop(ctx);
                  _loadOrgTree();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت الإضافة بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeTile(Map<String, dynamic> node, {int level = 0}) {
    final children = List<Map<String, dynamic>>.from(node['children'] ?? []);
    final hasChildren = children.isNotEmpty;
    final unitName = node['unit_name'] ?? '';
    final unitCode = node['unit_code'] ?? '';
    final hierarchyLevel = node['hierarchy_level'] ?? '';
    
    IconData icon;
    Color iconColor;
    
    switch (hierarchyLevel) {
      case 'WATER_ADMIN':
        icon = Icons.account_balance;
        iconColor = Colors.purple;
        break;
      case 'DIRECTORATE':
        icon = Icons.business;
        iconColor = Colors.blue;
        break;
      case 'DEPARTMENT':
        icon = Icons.account_tree;
        iconColor = Colors.green;
        break;
      case 'SECTION':
        icon = Icons.group;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.folder;
        iconColor = Colors.grey;
    }

    return ExpansionTile(
      leading: Padding(
        padding: EdgeInsets.only(left: level * 20.0),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        unitName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$unitCode - $hierarchyLevel'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
            tooltip: 'إضافة وحدة فرعية',
            onPressed: () => _showAddUnitDialog(parentId: node['org_unit_id']),
          ),
          if (hasChildren)
            Icon(
              _expanded ? Icons.expand_more : Icons.chevron_right,
              color: Colors.grey,
            ),
        ],
      ),
      children: children.map((child) => _buildTreeTile(child, level: level + 1)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الهيكل التنظيمي'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrgTree,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddUnitDialog(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orgTree.isEmpty
              ? const Center(child: Text('لا يوجد هيكل تنظيمي'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الهيكل التنظيمي',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'عدد الوحدات: ${_flatUnits.length}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Column(
                            children: _orgTree.map((node) => _buildTreeTile(node)).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
