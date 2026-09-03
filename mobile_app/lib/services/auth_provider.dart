import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/services.dart';
import '../services/api_service.dart';
import '../services/notification_ws.dart';
import '../services/location_tracker.dart';
import '../models/employee.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Profile? _profile;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  int _unreadCount = 0;

  Profile? get profile => _profile;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.containsKey('access_token');
    if (_isLoggedIn) {
      try {
        _profile = await _authService.getProfile();
        await _connectLive();
        await refreshUnread();
        LocationTrackerService.instance.start();
      } catch (e) {
        _isLoggedIn = false;
        await _authService.logout();
      }
    }
    notifyListeners();
  }

  Future<bool> login(String employeeNumber, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.login(employeeNumber, password);
      _profile = await _authService.getProfile();
      _isLoggedIn = true;
      await _connectLive();
      await refreshUnread();
      LocationTrackerService.instance.start();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _connectLive() async {
    final token = await apiService.token;
    if (token == null) return;
    NotificationWsService.instance.connect(token);
    NotificationWsService.instance.stream.listen((_) {
      _unreadCount += 1;
      notifyListeners();
    });
  }

  Future<void> refreshUnread() async {
    try {
      final items = await NotificationService().getNotifications();
      _unreadCount = items.where((e) => e['is_read'] == false).length;
      notifyListeners();
    } catch (_) {}
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> logout() async {
    NotificationWsService.instance.disconnect();
    await LocationTrackerService.instance.stop();
    await _authService.logout();
    _profile = null;
    _isLoggedIn = false;
    _unreadCount = 0;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _profile?.permissions.contains(permission) ?? false;
  }

  bool get isManager => _profile?.isManager ?? false;
  bool get isGM => _profile?.isGM ?? false;
  bool get isHR => _profile?.isHR ?? false;
  List<String> get roles => _profile?.roles ?? [];
}
