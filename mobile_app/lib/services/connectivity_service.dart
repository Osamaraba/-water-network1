import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Network connectivity checker service
/// Detects network changes and provides online/offline status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  
  ConnectivityService._();
  
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isOnline = false;
  bool get isOnline => _isOnline;
  
  /// Stream of connectivity changes
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// Initialize connectivity monitoring
  void initialize() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _checkInternetConnection();
    });
    
    // Initial check
    _checkInternetConnection();
  }
  
  /// Check actual internet connection
  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (wasOnline != _isOnline) {
        _connectionController.add(_isOnline);
      }
    } on SocketException catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _connectionController.add(false);
      }
    } on TimeoutException catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _connectionController.add(false);
      }
    }
  }
  
  /// Check if connected to internet
  Future<bool> checkConnection() async {
    await _checkInternetConnection();
    return _isOnline;
  }
  
  /// Dispose resources
  void dispose() {
    _connectionController.close();
  }
}

/// Widget that rebuilds based on connectivity status
class ConnectivityWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, bool isOnline)? builder;
  
  const ConnectivityWidget({
    Key? key,
    required this.child,
    this.builder,
  }) : super(key: key);
  
  @override
  State<ConnectivityWidget> createState() => _ConnectivityWidgetState();
}

class _ConnectivityWidgetState extends State<ConnectivityWidget> {
  bool _isOnline = true;
  
  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    
    ConnectivityService.instance.connectionStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(context, _isOnline);
    }
    return widget.child;
  }
}

/// Show a snackbar when offline
void showOfflineSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 8),
          const Text('لا يوجد اتصال بالإنترنت'),
        ],
      ),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ),
  );
}
