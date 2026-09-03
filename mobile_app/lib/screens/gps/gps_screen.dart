import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/services.dart';
import '../../services/auth_provider.dart';
import '../../models/employee.dart';
import '../../utils/report_pdf.dart';
import '../../theme/app_theme.dart';
import 'breach_report_screen.dart';

const _COLOR_OPTIONS = <String, Color>{
  'أحمر': Colors.red,
  'أزرق': Colors.blue,
  'أخضر': Colors.green,
  'برتقالي': Colors.orange,
  'بنفسجي': Colors.purple,
  'أصفر': Colors.amber,
  'وردي': Colors.pink,
  'بني': Colors.brown,
};

Color _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.blue;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return Colors.blue;
  }
}

String _colorToHex(Color c) => '#${c.value.toRadixString(16).substring(2)}';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});
  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  final _gps = GpsService();
  final _empService = EmployeeService();
  bool _loading = true;
  bool _isGmOrHr = false;
  bool _isViewer = false;
  bool _isOfficeSupervisor = false;
  List<Employee> _employees = [];
  List<Map<String, dynamic>> _employeeDir = [];
  List<Map<String, dynamic>> _active = [];
  Map<int, List<Map<String, dynamic>>> _historyById = {};
  bool _isTracked = false;
  Map<String, dynamic> _myActive = {};
  Timer? _poll;
  Timer? _tick;

  Employee? _targetSel;
  Employee? _viewerSel;
  String _mode = 'distance';
  int _interval = 100;
  Color _selectedColor = Colors.blue;
  Map<String, dynamic>? _viewerInfo;

  int? _viewerSelectedEmp;
  List<Map<String, dynamic>> _viewerPoints = [];
  Map<String, dynamic> _viewerActive = {};

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      _isGmOrHr = auth.isGM || auth.isHR;
      _isOfficeSupervisor = auth.roles.contains('office_supervisor');
      if (_isGmOrHr) {
        _employees = await _empService.listEmployees();
      } else if (_isOfficeSupervisor) {
        final v = await _gps.getViewer();
        _isViewer = v['is_viewer'] == true;
        _viewerInfo = v['viewer'];
        if (_isViewer) {
          final dir = await _gps.getEmployees();
          _employeeDir = List<Map<String, dynamic>>.from(dir['items'] ?? []);
        }
      } else {
        _myActive = await _gps.myActive();
        _isTracked = _myActive['active'] == true;
      }
      if (_isGmOrHr) await _refreshView();
    } catch (e) {
      debugPrint('gps load: $e');
    }
    if (mounted) {
      setState(() => _loading = false);
      _startPolling();
    }
  }

  void _startPolling() {
    _poll?.cancel();
    if (_isGmOrHr || _active.isNotEmpty) {
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refreshView());
    } else if (_isTracked) {
      _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          _myActive = await _gps.myActive();
          if (mounted) setState(() {});
        } catch (_) {}
      });
    }
  }

  Future<void> _refreshView() async {
    try {
      final v = await _gps.getView();
      _active = List<Map<String, dynamic>>.from(v['items'] ?? []);
      for (final s in _active) {
        final tid = s['target']?['employee_id'];
        if (tid != null) {
          try {
            final h = await _gps.getHistory(tid);
            _historyById[tid] = List<Map<String, dynamic>>.from(h['points'] ?? []);
          } catch (_) {}
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Duration _outsideDuration(Map<String, dynamic> item) {
    if (item['is_outside'] != true) return Duration.zero;
    final s = item['outside_started_at'];
    if (s == null) return Duration.zero;
    final dt = DateTime.tryParse(s);
    return dt == null ? Duration.zero : DateTime.now().difference(dt);
  }

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final p = <String>[];
    if (h > 0) p.add('$h س');
    if (m > 0) p.add('$m د');
    if (s > 0 || p.isEmpty) p.add('$s ث');
    return p.join(' ');
  }

  Future<void> _start() async {
    if (_targetSel == null) return _snack('اختر الموظف المراد تتبّعه');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد بدء التتبع'),
        content: Text('هل تريد بدء تتبّع الموظف "${_targetSel!.fullName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('بدء', style: TextStyle(color: Colors.green))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _gps.startTracking(
        targetEmployeeId: _targetSel!.employeeId,
        mode: _mode,
        interval: _interval,
        trackColor: _colorToHex(_selectedColor),
      );
      await _refreshView();
      _snack('تم بدء التتبع', color: Colors.green);
    } catch (e) {
      _snack('تعذر البدء: $e', color: AppTheme.danger);
    }
  }

  Future<void> _stop(int sid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد إيقاف التتبع'),
        content: const Text('هل تريد إيقاف التتبع؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('إيقاف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _gps.stopTracking(sessionId: sid);
      await _refreshView();
      _snack('تم إيقاف التتبع');
    } catch (e) {
      _snack('تعذر الإيقاف: $e', color: AppTheme.danger);
    }
  }

  Future<void> _saveViewer() async {
    if (_viewerSel == null) return _snack('اختر الموظف المفوض');
    try {
      await _gps.setViewer(_viewerSel!.employeeId);
      _snack('تم تعيين الموظف المفوض', color: Colors.green);
      final v = await _gps.getViewer();
      _viewerInfo = v['viewer'];
      setState(() {});
    } catch (e) {
      _snack('تعذر التعيين: $e', color: AppTheme.danger);
    }
  }

  Future<void> _simulate(Map<String, dynamic> item) async {
    final t = item['target'] ?? {};
    final glat = t['geofence_lat'];
    final glng = t['geofence_lng'];
    if (glat == null || glng == null) {
      return _snack('الموظف ليس له منطقة عمل محددة', color: AppTheme.danger);
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('محاكاة موقع'),
        content: const Text('أرسل نقطة تجريبية:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'inside'), child: const Text('داخل المنطقة')),
          TextButton(onPressed: () => Navigator.pop(context, 'outside'), child: const Text('خارج المنطقة')),
        ],
      ),
    );
    if (choice == null) return;
    final lat = (choice == 'inside' ? glat : glat + 0.003).toDouble();
    final lng = (choice == 'inside' ? glng : glng + 0.003).toDouble();
    try {
      await _gps.simulatePoint(sessionId: item['session_id'], latitude: lat, longitude: lng);
      await _refreshView();
      _snack('تم إرسال نقطة تجريبية', color: Colors.green);
    } catch (e) {
      _snack('تعذر المحاكاة: $e', color: AppTheme.danger);
    }
  }

  Future<void> _viewerPick(int empId) async {
    setState(() => _viewerSelectedEmp = empId);
    try {
      final emp = _employeeDir.firstWhere((e) => e['employee_id'] == empId, orElse: () => {});
      _viewerPoints = List<Map<String, dynamic>>.from(emp['points'] ?? []);
      _viewerActive = _active.firstWhere(
        (s) => s['target']?['employee_id'] == empId,
        orElse: () => <String, dynamic>{},
      );
      setState(() {});
    } catch (e) {
      _snack('تعذر تحميل المسير: $e', color: AppTheme.danger);
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع المواقع'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isGmOrHr || _isViewer)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'سجل الخروقات',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreachReportScreen())),
            ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isGmOrHr) return _managerView();
    if (_isViewer || _isOfficeSupervisor) return _viewerView();
    if (_isTracked) return _trackedView();
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('لا يوجد تتبع نشط لك في الوقت الحالي', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _trackedView() {
    final outside = _myActive['is_outside'] == true;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(outside ? Icons.warning : Icons.gps_fixed, size: 64, color: outside ? Colors.orange : Colors.green),
            const SizedBox(height: 16),
            Text(outside ? 'أنت خارج منطقة عملك!' : 'يتم تتبّع موقعك الآن', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(outside ? 'زمن خارج المنطقة: ${_fmtDur(_outsideDuration(_myActive))}' : 'يُرسل تطبيقك موقعك تلقائياً',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            if (outside)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('المسافة المقطوعة خارج المنطقة: ${(_myActive['outside_distance_m'] ?? 0).toStringAsFixed(0)} م',
                    style: const TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _managerView() {
    final intervalOptions = _mode == 'distance' ? [50, 100, 150, 200] : [1, 5, 10, 15, 30];
    if (!intervalOptions.contains(_interval)) _interval = intervalOptions.first;

    return Row(
      children: [
        // Main content area
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Forms area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Viewer card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الموظف المفوض (يطبع المسير فقط):', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<Employee>(
                                      decoration: const InputDecoration(labelText: 'الموظف المفوض', border: OutlineInputBorder()),
                                      value: _viewerSel,
                                      items: _employees.map((e) => DropdownMenuItem(value: e, child: Text('${e.fullName} (${e.employeeNumber})'))).toList(),
                                      onChanged: (v) => setState(() => _viewerSel = v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _saveViewer,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                                    child: const Text('حفظ'),
                                  ),
                                ],
                              ),
                              if (_viewerInfo != null)
                                Padding(padding: const EdgeInsets.only(top: 6), child: Text('الحالي: ${_viewerInfo!['full_name']}', style: const TextStyle(color: Colors.green))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tracking start card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<Employee>(
                                decoration: const InputDecoration(labelText: 'الموظف المراد تتبّعه', border: OutlineInputBorder()),
                                value: _targetSel,
                                items: _employees.map((e) => DropdownMenuItem(value: e, child: Text('${e.fullName} (${e.employeeNumber})'))).toList(),
                                onChanged: (v) => setState(() => _targetSel = v),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(labelText: 'وضع التتبع', border: OutlineInputBorder()),
                                      value: _mode,
                                      items: const [
                                        DropdownMenuItem(value: 'distance', child: Text('حسب المسافة')),
                                        DropdownMenuItem(value: 'time', child: Text('حسب الزمن')),
                                      ],
                                      onChanged: (v) => setState(() => _mode = v ?? 'distance'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: InputDecoration(labelText: _mode == 'distance' ? 'المسافة (متر)' : 'الزمن (دقيقة)', border: const OutlineInputBorder()),
                                      value: _interval,
                                      items: intervalOptions.map((i) => DropdownMenuItem(value: i, child: Text('$i'))).toList(),
                                      onChanged: (v) => setState(() => _interval = v ?? _interval),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Align(alignment: Alignment.centerRight, child: Text('لون الموظف على الخريطة:', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _COLOR_OPTIONS.entries.map((e) {
                                  final selected = _selectedColor.value == e.value.value;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedColor = e.value),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: e.value,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: selected ? Colors.black : Colors.grey.shade300, width: selected ? 3 : 1),
                                      ),
                                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('بدء التتبع'),
                                  onPressed: _start,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Collapsible map at bottom
              if (_active.isNotEmpty)
                _CollapsibleMap(
                  active: _active,
                  historyById: _historyById,
                ),
            ],
          ),
        ),
        // Side drawer for employee list
        if (_active.isNotEmpty)
          SizedBox(
            width: 320,
            child: _EmployeeListDrawer(
              active: _active,
              historyById: _historyById,
              onSimulate: _simulate,
              onStop: _stop,
              fmtDur: _fmtDur,
              outsideDuration: _outsideDuration,
            ),
          ),
      ],
    );
  }

  void _showUnifiedMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _UnifiedMapPage(active: _active, historyById: _historyById),
      ),
    );
  }

  Widget _viewerView() {
    final outside = _viewerActive['is_outside'] == true;
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر موظفاً لعرض/طباعة مسيره:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'الموظف', border: OutlineInputBorder()),
                  value: _viewerSelectedEmp,
                  items: _employeeDir.map((e) => DropdownMenuItem(
                    value: e['employee_id'] as int,
                    child: Text('${e['full_name']} (${e['employee_number']})'),
                  )).toList(),
                  onChanged: (v) => _viewerPick(v!),
                ),
              ],
            ),
          ),
        ),
        if (_viewerSelectedEmp != null)
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.green.shade50,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'مسير: ${_employeeDir.firstWhere((e) => e['employee_id'] == _viewerSelectedEmp, orElse: () => {'full_name': ''})['full_name']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.print),
                            label: const Text('طباعة المسير'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                            onPressed: _viewerPoints.isEmpty
                                ? null
                                : () async {
                                    final emp = _employeeDir.firstWhere((e) => e['employee_id'] == _viewerSelectedEmp);
                                    final mode = _viewerActive['track_mode'] ?? 'distance';
                                    final interval = _viewerActive['track_interval'] ?? 50;
                                    try {
                                      await ReportPdf.shareRoute(
                                        employeeName: emp['full_name'] ?? '',
                                        mode: mode,
                                        interval: interval,
                                        points: _viewerPoints,
                                        outsideCount: _countOutsideEvents(_viewerPoints),
                                        totalDistanceM: _calcTotalDistance(_viewerPoints),
                                      );
                                    } catch (e) {
                                      _snack('تعذر الطباعة: $e', color: AppTheme.danger);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _TrackingMap(
                        item: _viewerActive.isNotEmpty ? _viewerActive : {'target': _employeeDir.firstWhere((e) => e['employee_id'] == _viewerSelectedEmp, orElse: () => <String, dynamic>{})},
                        points: _viewerPoints,
                      ),
                    ),
                  ],
                ),
                if (outside)
                  Align(
                    alignment: Alignment.center,
                    child: Card(
                      color: Colors.orange.shade100,
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('خارج منطقة العمل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(height: 6),
                            Text('الزمن: ${_fmtDur(_outsideDuration(_viewerActive))}', style: const TextStyle(fontSize: 15)),
                            Text('المسافة: ${(_viewerActive['outside_distance_m'] ?? 0).toStringAsFixed(0)} م', style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  int _countOutsideEvents(List<Map<String, dynamic>> points) {
    int count = 0;
    for (final p in points) {
      if (p['is_outside'] == true) count++;
    }
    return count;
  }

  double _calcTotalDistance(List<Map<String, dynamic>> points) {
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      if (p1['latitude'] != null && p2['latitude'] != null) {
        total += _haversine(p1['latitude'], p1['longitude'], p2['latitude'], p2['longitude']);
      }
    }
    return total;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final p = math.pi / 180.0;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 + math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 2 * R * math.asin(math.sqrt(a));
  }
}

// Collapsible map widget at bottom
class _CollapsibleMap extends StatefulWidget {
  final List<Map<String, dynamic>> active;
  final Map<int, List<Map<String, dynamic>>> historyById;
  const _CollapsibleMap({required this.active, required this.historyById});

  @override
  State<_CollapsibleMap> createState() => _CollapsibleMapState();
}

class _CollapsibleMapState extends State<_CollapsibleMap> {
  bool _expanded = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    for (final s in widget.active) {
      _selected.add(s['target']?['employee_id'] ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _expanded ? 300 : 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(_expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, size: 20),
                  const SizedBox(width: 6),
                  Icon(Icons.map, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text('الخريطة (${widget.active.length} موظف)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  ...widget.active.take(5).map((s) {
                    final c = _colorFromHex(s['track_color']);
                    return Container(
                      width: 12, height: 12,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (_expanded)
            Expanded(
              child: _UnifiedMapContent(
                active: widget.active,
                historyById: widget.historyById,
                selected: _selected,
                onToggle: (eid) {
                  setState(() {
                    if (_selected.contains(eid)) _selected.remove(eid);
                    else _selected.add(eid);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Employee list drawer on the side
class _EmployeeListDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> active;
  final Map<int, List<Map<String, dynamic>>> historyById;
  final Future<void> Function(Map<String, dynamic>) onSimulate;
  final Future<void> Function(int) onStop;
  final String Function(Duration) fmtDur;
  final Duration Function(Map<String, dynamic>) outsideDuration;

  const _EmployeeListDrawer({
    required this.active,
    required this.historyById,
    required this.onSimulate,
    required this.onStop,
    required this.fmtDur,
    required this.outsideDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primary,
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('الموظفون النشطون (${active.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: active.isEmpty
                ? const Center(child: Text('لا توجد جلسات نشطة', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: active.length,
                    itemBuilder: (ctx, i) {
                      final item = active[i];
                      final target = item['target'] ?? {};
                      final pts = historyById[target['employee_id']] ?? [];
                      final outside = item['is_outside'] == true;
                      final color = _colorFromHex(item['track_color']);
                      final name = target['full_name'] ?? '';
                      final empNum = target['employee_number'] ?? '';
                      final mode = item['track_mode'] == 'time' ? 'زمن' : 'مسافة';
                      final interval = item['track_interval'] ?? '';
                      final viewer = item['viewer_name'];
                      final outsideDist = (item['outside_distance_m'] ?? 0).toStringAsFixed(0);
                      final outsideTime = fmtDur(outsideDuration(item));

                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: color,
                            child: outside
                                ? const Icon(Icons.warning, color: Colors.white, size: 18)
                                : Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$empNum | $mode $interval', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              if (viewer != null) Text('المتابع: $viewer', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                              if (outside)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text('خارج | $outsideTime | $outsideDist م', style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('النقاط: ${pts.length}', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.gps_fixed, size: 16, color: Colors.blue),
                                        label: const Text('محاكاة', style: TextStyle(fontSize: 12)),
                                        onPressed: () => onSimulate(item),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.stop, size: 16, color: Colors.red),
                                        label: const Text('إيقاف', style: TextStyle(fontSize: 12)),
                                        onPressed: () => onStop(item['session_id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

// Reusable unified map content
class _UnifiedMapContent extends StatelessWidget {
  final List<Map<String, dynamic>> active;
  final Map<int, List<Map<String, dynamic>>> historyById;
  final Set<int> selected;
  final void Function(int) onToggle;

  const _UnifiedMapContent({
    required this.active,
    required this.historyById,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: active.length,
            itemBuilder: (ctx, i) {
              final s = active[i];
              final eid = s['target']?['employee_id'] ?? 0;
              final color = _colorFromHex(s['track_color']);
              final isSelected = selected.contains(eid);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FilterChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(s['target']?['full_name'] ?? '', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  onSelected: (_) => onToggle(eid),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(initialCenter: const LatLng(32.0, 35.0), initialZoom: 12),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.yarmouk.water.pro'),
              PolylineLayer(
                polylines: [
                  for (final s in active)
                    if (selected.contains(s['target']?['employee_id']))
                      ..._buildPolylines(s),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final s in active)
                    if (selected.contains(s['target']?['employee_id']))
                      ..._buildMarkers(s),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Polyline> _buildPolylines(Map<String, dynamic> s) {
    final pts = historyById[s['target']?['employee_id']] ?? [];
    if (pts.length < 2) return [];
    return [Polyline(
      points: pts.where((p) => p['latitude'] != null && p['longitude'] != null).map((p) => LatLng(p['latitude'], p['longitude'])).toList(),
      color: _colorFromHex(s['track_color']),
      strokeWidth: 4,
    )];
  }

  List<Marker> _buildMarkers(Map<String, dynamic> s) {
    final pts = historyById[s['target']?['employee_id']] ?? [];
    if (pts.isEmpty || pts.last['latitude'] == null) return [];
    return [Marker(
      point: LatLng(pts.last['latitude'], pts.last['longitude']),
      width: 32, height: 32,
      child: Icon(Icons.person_pin_circle, color: _colorFromHex(s['track_color']), size: 28),
    )];
  }
}

class _TrackingMap extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> points;
  final Color color;
  const _TrackingMap({required this.item, this.points = const [], this.color = Colors.blue});

  @override
  State<_TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<_TrackingMap> {
  final MapController _controller = MapController();

  LatLng _center() {
    if (widget.points.isNotEmpty) {
      final p = widget.points.last;
      if (p['latitude'] != null && p['longitude'] != null) return LatLng(p['latitude'], p['longitude']);
    }
    final target = widget.item['target'] ?? {};
    final gLat = target['geofence_lat'];
    final gLng = target['geofence_lng'];
    if (gLat != null && gLng != null) return LatLng(gLat, gLng);
    return const LatLng(32.0, 35.0);
  }

  @override
  void didUpdateWidget(covariant _TrackingMap old) {
    super.didUpdateWidget(old);
    try { _controller.move(_center(), 16); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.item['target'] ?? {};
    final gLat = target['geofence_lat'];
    final gLng = target['geofence_lng'];
    final radius = target['geofence_radius_m'];

    final markers = <Marker>[];
    if (widget.points.isNotEmpty) {
      final last = widget.points.last;
      if (last['latitude'] != null && last['longitude'] != null) {
        markers.add(Marker(
          point: LatLng(last['latitude'], last['longitude']),
          width: 40, height: 40,
          child: Icon(Icons.person_pin_circle, color: widget.color, size: 36),
        ));
      }
    }
    final circles = <CircleMarker>[];
    if (gLat != null && gLng != null && radius != null) {
      circles.add(CircleMarker(
        point: LatLng(gLat, gLng),
        radius: (radius as num).toDouble(),
        useRadiusInMeter: true,
        color: widget.color.withOpacity(0.15),
        borderStrokeWidth: 2,
        borderColor: widget.color,
      ));
    }
    final polylines = <Polyline>[];
    if (widget.points.length >= 2) {
      polylines.add(Polyline(
        points: widget.points.where((p) => p['latitude'] != null && p['longitude'] != null).map((p) => LatLng(p['latitude'], p['longitude'])).toList(),
        color: widget.color,
        strokeWidth: 4,
      ));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(initialCenter: _center(), initialZoom: 16),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.yarmouk.water.pro'),
            CircleLayer(circles: circles),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
        if (widget.points.isEmpty)
          const Align(
            alignment: Alignment.center,
            child: Card(color: Colors.white70, child: Padding(padding: EdgeInsets.all(12), child: Text('بانتظار وصول أول نقطة...', style: TextStyle(color: Colors.black87)))),
          ),
      ],
    );
  }
}

class _UnifiedMapPage extends StatefulWidget {
  final List<Map<String, dynamic>> active;
  final Map<int, List<Map<String, dynamic>>> historyById;
  const _UnifiedMapPage({required this.active, required this.historyById});

  @override
  State<_UnifiedMapPage> createState() => _UnifiedMapPageState();
}

class _UnifiedMapPageState extends State<_UnifiedMapPage> {
  final Set<int> _selectedEmployees = {};

  @override
  void initState() {
    super.initState();
    for (final s in widget.active) {
      _selectedEmployees.add(s['target']?['employee_id'] ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخريطة الموحدة'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _UnifiedMapContent(
        active: widget.active,
        historyById: widget.historyById,
        selected: _selectedEmployees,
        onToggle: (eid) {
          setState(() {
            if (_selectedEmployees.contains(eid)) _selectedEmployees.remove(eid);
            else _selectedEmployees.add(eid);
          });
        },
      ),
    );
  }
}
