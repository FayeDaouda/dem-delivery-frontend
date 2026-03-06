import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketEventType {
  driverOnline,
  driverOffline,
  deliveryAssigned,
  deliveryStatusChanged,
  deliveryCompleted,
  passActivated,
  unknown,
}

class WebSocketEvent {
  final WebSocketEventType type;
  final String name;
  final Map<String, dynamic> data;

  WebSocketEvent({
    required this.type,
    required this.name,
    required this.data,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final rawName = (json['type'] ?? json['event'] ?? '').toString().trim();
    final typeStr = rawName.toLowerCase();
    final type = _parseEventType(typeStr);
    final payload = json['data'];

    return WebSocketEvent(
      type: type,
      name: rawName.isEmpty ? 'unknown' : typeStr,
      data: payload is Map<String, dynamic>
          ? payload
          : payload is Map
              ? Map<String, dynamic>.from(payload)
              : {},
    );
  }

  static WebSocketEventType _parseEventType(String typeStr) {
    switch (typeStr) {
      case 'driver_online':
        return WebSocketEventType.driverOnline;
      case 'driver_offline':
        return WebSocketEventType.driverOffline;
      case 'delivery_assigned':
      case 'delivery-created':
        return WebSocketEventType.deliveryAssigned;
      case 'delivery_status_changed':
      case 'delivery_updated':
        return WebSocketEventType.deliveryStatusChanged;
      case 'delivery_completed':
        return WebSocketEventType.deliveryCompleted;
      case 'pass_activated':
        return WebSocketEventType.passActivated;
      default:
        return WebSocketEventType.unknown;
    }
  }
}

abstract class SocketService {
  Stream<WebSocketEvent> get events;
  Future<void> connect(String url, String accessToken);
  Future<void> disconnect();
  void sendMessage(Map<String, dynamic> message);
  void emit(String event, Map<String, dynamic> data);
  bool get isConnected;
}

class SocketServiceImpl implements SocketService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  final List<Map<String, dynamic>> _pendingMessages = [];
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _lastUrl;
  String? _lastAccessToken;
  static const int _maxReconnectAttempts = 5;

  @override
  Stream<WebSocketEvent> get events => _eventController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  void emit(String event, Map<String, dynamic> data) {
    sendMessage({'type': event, 'data': data});
  }

  @override
  Future<void> connect(String url, String accessToken) async {
    _lastUrl = url;
    _lastAccessToken = accessToken;

    try {
      await disconnect();

      _channel = WebSocketChannel.connect(
        Uri.parse('$url?token=$accessToken'),
      );

      _isConnected = true;
      _isReconnecting = false;
      _reconnectAttempts = 0;
      _startHeartbeat();
      _flushPendingMessages();

      _channel?.stream.listen(
        (dynamic message) {
          try {
            final json = _toJsonMap(message);

            final event = WebSocketEvent.fromJson(json);
            _eventController.add(event);
          } catch (e) {
            // ignore parsing failures but keep socket alive
          }
        },
        onError: (error) {
          _markDisconnected();
          _scheduleReconnect();
        },
        onDone: () {
          _markDisconnected();
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _markDisconnected();
      _scheduleReconnect();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _reconnectTimer?.cancel();
      _heartbeatTimer?.cancel();
      await _channel?.sink.close();
      _markDisconnected();
    } catch (e) {
      _markDisconnected();
    }
  }

  @override
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected) {
      _channel?.sink.add(jsonEncode(message));
    } else {
      _pendingMessages.add(message);
    }
  }

  Map<String, dynamic> _toJsonMap(dynamic message) {
    if (message is Map<String, dynamic>) {
      return message;
    }
    if (message is Map) {
      return Map<String, dynamic>.from(message);
    }
    if (message is String) {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'type': 'unknown', 'data': {}};
    }
    return {'type': 'unknown', 'data': {}};
  }

  void _markDisconnected() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
  }

  void _scheduleReconnect() {
    if (_isReconnecting || _lastUrl == null || _lastAccessToken == null) {
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _isReconnecting = true;
    _reconnectAttempts += 1;
    final backoffSeconds = _reconnectAttempts * 2;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () async {
      _isReconnecting = false;
      try {
        await connect(_lastUrl!, _lastAccessToken!);
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  void _flushPendingMessages() {
    if (!_isConnected || _pendingMessages.isEmpty) return;
    final toSend = List<Map<String, dynamic>>.from(_pendingMessages);
    _pendingMessages.clear();
    for (final msg in toSend) {
      sendMessage(msg);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected) {
        sendMessage({
          'type': 'ping',
          'data': {'timestamp': DateTime.now().toIso8601String()},
        });
      }
    });
  }

  void dispose() {
    _eventController.close();
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
  }
}
