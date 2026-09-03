import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/services.dart';
import '../../models/employee.dart';
import '../../theme/app_theme.dart';

class LiveTrackingPage extends StatefulWidget {
  final int sessionId;
  const LiveTrackingPage({super.key, required this.sessionId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final _service = GpsService();
  final MapController _mapController = MapController();
  LatLng? _current;
  Employee? _me;
  bool _loading = true;
  bool _tracking = true;
  String? _error;
  bool _outside = false;
  StreamSubscription<Position>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _me = await EmployeeService().getMyEmployee();
    } catch (_) {}
    await _startLocation();
  }

  Future<void> _startLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _error = 'خدمة الموقع غير مفعّلة');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _error = 'صلاحية الموقع مطلوبة للتتبع');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _update(pos);

      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen(_update);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحديد الموقع: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _update(Position pos) {
    final newPoint = LatLng(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _current = newPoint;
        _error = null;
        _checkGeofence();
      });
    }
    try {
      _mapController.move(newPoint, 16);
    } catch (_) {}

    _service
        .addPoint(
      sessionId: widget.sessionId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
    ).then((res) {
      if (mounted && res['is_outside'] != null) {
        setState(() => _outside = res['is_outside'] == true);
      }
    }).catchError((_, __) {});
  }

  void _checkGeofence() {
    if (_me == null ||
        _me!.geofenceLat == null ||
        _me!.geofenceLng == null ||
        _current == null) {
      _outside = false;
      return;
    }
    if (_me!.geofenceExempt) {
      _outside = false;
      return;
    }
    final center = LatLng(_me!.geofenceLat!, _me!.geofenceLng!);
    final radius = (_me!.geofenceRadiusM ?? 200).toDouble();
    final dist = const Distance().distance(center, _current!);
    _outside = dist > radius;
  }

  Future<void> _stop() async {
    try {
      await _service.stopTracking();
    } catch (_) {}
    await _sub?.cancel();
    _sub = null;
    if (mounted) {
      setState(() => _tracking = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasGeofence = _me?.geofenceLat != null && _me?.geofenceLng != null;

    return WillPopScope(
      onWillPop: () async {
        await _stop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('صفحة التتبع الحي'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.stop_circle),
              tooltip: 'إيقاف التتبع',
              onPressed: _stop,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.all(10),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            Container(
              width: double.infinity,
              color: _outside ? Colors.red.shade50 : Colors.green.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    _tracking ? Icons.gps_fixed : Icons.gps_off,
                    color: _tracking ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _outside
                          ? 'خارج نطاق موقع العمل المسموح'
                          : (_tracking ? 'جلسة التتبع نشطة' : 'التتبع متوقف'),
                      style: TextStyle(
                        color: _outside ? Colors.red : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_current != null)
                    Text(
                      '${_current!.latitude.toStringAsFixed(5)}, ${_current!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading && _current == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _current ?? const LatLng(32.0, 35.0),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.yarmouk.water.pro',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        if (hasGeofence)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(
                                    _me!.geofenceLat!, _me!.geofenceLng!),
                                radius:
                                    (_me!.geofenceRadiusM ?? 200).toDouble(),
                                useRadiusInMeter: true,
                                color: _outside
                                    ? Colors.red.withOpacity(0.12)
                                    : Colors.blue.withOpacity(0.15),
                                borderStrokeWidth: 2,
                                borderColor:
                                    _outside ? Colors.red : Colors.blue,
                              ),
                            ],
                          ),
                        if (_current != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _current!,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.my_location,
                                    color: Colors.red, size: 36),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
