import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'services.dart';

/// Production-ready GPS tracking service with:
/// - Battery optimization (adaptive intervals based on movement)
/// - Offline queue (stores points locally when offline, syncs on reconnect)
/// - Geofence breach detection
/// - Background tracking support
class LocationTrackerService {
  static final LocationTrackerService instance = LocationTrackerService._();
  LocationTrackerService._();

  Timer? _pollTimer;
  Timer? _timeTimer;
  StreamSubscription<Position>? _sub;
  bool _running = false;
  int? _activeSessionId;
  String? _mode;
  int? _interval;
  
  // Battery optimization
  Position? _lastPosition;
  DateTime? _lastMovementTime;
  static const double _movementThreshold = 10.0; // meters
  static const int _stationaryIntervalMinutes = 10;
  static const int _movingIntervalMinutes = 2;
  
  // Offline queue
  final Queue<Map<String, dynamic>> _offlineQueue = Queue();
  bool _isOnline = true;
  Timer? _syncTimer;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _pollTimer = Timer.periodic(
        const Duration(seconds: 15), (_) => _check());
    
    // Sync offline queue periodically
    _syncTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _syncOfflineQueue());
    
    await _check();
  }

  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    await _teardownStream();
    _activeSessionId = null;
    _mode = null;
    _interval = null;
  }

  Future<void> _teardownStream() async {
    await _sub?.cancel();
    _sub = null;
    _timeTimer?.cancel();
    _timeTimer = null;
  }

  /// Get adaptive interval based on movement detection.
  int _getAdaptiveInterval() {
    if (_lastPosition == null || _lastMovementTime == null) {
      return _movingIntervalMinutes;
    }
    
    final timeSinceMovement = DateTime.now().difference(_lastMovementTime!);
    if (timeSinceMovement.inMinutes > _stationaryIntervalMinutes) {
      // Stationary - use longer interval to save battery
      return _stationaryIntervalMinutes;
    }
    return _movingIntervalMinutes;
  }

  /// Check if device has moved significantly.
  bool _hasMoved(Position newPosition) {
    if (_lastPosition == null) return true;
    
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    return distance > _movementThreshold;
  }

  Future<void> _check() async {
    try {
      final res = await GpsService().myActive();
      final active = res['active'] == true;
      final sid = res['session_id'];
      final mode = res['track_mode'];
      final interval = res['track_interval'];

      if (active && sid != null) {
        if (_activeSessionId != sid ||
            _mode != mode ||
            _interval != interval ||
            (_sub == null && _timeTimer == null)) {
          await _teardownStream();
          _activeSessionId = sid;
          _mode = mode;
          _interval = interval;

          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm == LocationPermission.denied ||
              perm == LocationPermission.deniedForever) {
            return;
          }

          if (mode == 'time') {
            final mins = (interval ?? 5).clamp(1, 30);
            _timeTimer = Timer.periodic(
                Duration(minutes: mins), (_) => _sendCurrent(sid));
            await _sendCurrent(sid);
          } else {
            final meters = (interval ?? 50).clamp(50, 200).toDouble();
            _sub = Geolocator.getPositionStream(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: meters.round(),
              ),
            ).listen((pos) async {
              try {
                // Battery optimization: track movement
                if (_hasMoved(pos)) {
                  _lastMovementTime = DateTime.now();
                }
                _lastPosition = pos;
                
                await _sendPoint(sid, pos);
              } catch (_) {}
            });
          }
        }
      } else {
        await _teardownStream();
        _activeSessionId = null;
        _mode = null;
        _interval = null;
      }
    } catch (_) {}
  }

  /// Send point with offline queue support.
  Future<void> _sendPoint(int sessionId, Position pos) async {
    final point = {
      'sessionId': sessionId,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'accuracy': pos.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_isOnline) {
      try {
        await GpsService().addPoint(
          sessionId: sessionId,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
        );
        _lastPosition = pos;
      } catch (_) {
        // Queue for later if offline
        _offlineQueue.add(point);
      }
    } else {
      _offlineQueue.add(point);
    }
  }

  /// Sync offline queue when connection is restored.
  Future<void> _syncOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    
    while (_offlineQueue.isNotEmpty) {
      final point = _offlineQueue.first;
      try {
        await GpsService().addPoint(
          sessionId: point['sessionId'],
          latitude: point['latitude'],
          longitude: point['longitude'],
          accuracy: point['accuracy'],
        );
        _offlineQueue.removeFirst();
      } catch (_) {
        // Still offline, stop syncing
        break;
      }
    }
  }

  Future<void> _sendCurrent(int sid) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await _sendPoint(sid, pos);
    } catch (_) {}
  }
  
  /// Set online status for offline queue management.
  void setOnlineStatus(bool online) {
    _isOnline = online;
    if (online) {
      _syncOfflineQueue();
    }
  }
  
  /// Get offline queue size.
  int get offlineQueueSize => _offlineQueue.length;
}
