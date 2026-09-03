import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

/// Live notifications channel with auto-reconnect and exponential backoff.
/// Connects to the backend WebSocket endpoint using the user's access token
/// and exposes a broadcast stream of incoming notifications.
class NotificationWsService {
  NotificationWsService._();
  static final NotificationWsService instance = NotificationWsService._();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  // Connection state
  String? _token;
  bool _intentionalDisconnect = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  
  // Configuration
  static const int _maxReconnectDelay = 30000; // 30 seconds max
  static const int _baseReconnectDelay = 1000; // 1 second base
  static const int _heartbeatInterval = 30000; // 30 seconds
  Timer? _heartbeatTimer;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _channel != null;
  int get reconnectAttempt => _reconnectAttempt;

  /// Connect to WebSocket with auto-reconnect support.
  void connect(String token) {
    _token = token;
    _intentionalDisconnect = false;
    _reconnectAttempt = 0;
    _connect();
  }

  void _connect() {
    if (_channel != null || _token == null) return;
    
    final wsBase = ApiConfig.apiBase.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsBase/ws/notifications?token=$_token');
    
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (event) {
          _reconnectAttempt = 0; // Reset on successful message
          try {
            final data = jsonDecode(event as String);
            
            // Handle heartbeat pong
            if (data['type'] == 'pong') return;
            
            _controller.add(data);
          } catch (_) {}
        },
        onError: (_) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );
      
      // Start heartbeat
      _startHeartbeat();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _stopHeartbeat();
    _channel = null;
    
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnect with exponential backoff.
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (max)
    final delay = min(
      _baseReconnectDelay * pow(2, _reconnectAttempt).toInt(),
      _maxReconnectDelay,
    );
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      _reconnectAttempt++;
      _connect();
    });
  }

  /// Start heartbeat to detect stale connections.
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: _heartbeatInterval),
      (_) {
        if (_channel != null) {
          try {
            _channel!.sink.add(jsonEncode({'type': 'ping'}));
          } catch (_) {
            _handleDisconnect();
          }
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Disconnect intentionally (no auto-reconnect).
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _close();
  }

  void _close() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Dispose resources.
  void dispose() {
    disconnect();
    _controller.close();
  }
}
