import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

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
  io.Socket? _socket;
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  final List<Map<String, dynamic>> _pendingMessages = [];
  bool _isConnected = false;

  static const List<String> _knownEvents = [
    'user:authenticated',
    'driver:location:received',
    'delivery:offer',
    'delivery:accepted',
    'delivery:picked_up',
    'delivery:delivered',
    'delivery:driver:location',
    'delivery:status:changed',
    'error',
  ];

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
    await disconnect();

    final uri = Uri.parse(url);
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    final namespace = (uri.path.isEmpty || uri.path == '/') ? '' : uri.path;
    final baseUrl = '$scheme://$host$port$namespace';

    final options = io.OptionBuilder()
        .setPath('/socket.io')
        .setTransports(['websocket'])
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000)
        .disableAutoConnect()
        .setQuery({'token': accessToken})
        .build();

    _socket = io.io(baseUrl, options);

    _socket!.onConnect((_) {
      _isConnected = true;
      _flushPendingMessages();
      _eventController.add(
        WebSocketEvent.fromJson({'event': 'connect', 'data': {}}),
      );
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _eventController.add(
        WebSocketEvent.fromJson({'event': 'disconnect', 'data': {}}),
      );
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      _eventController.add(
        WebSocketEvent.fromJson({
          'event': 'error',
          'data': {'message': error.toString()},
        }),
      );
    });

    for (final eventName in _knownEvents) {
      _socket!.on(eventName, (payload) {
        final data = _normalizePayload(payload);
        _eventController.add(
          WebSocketEvent.fromJson({'event': eventName, 'data': data}),
        );
      });
    }

    _socket!.connect();
  }

  @override
  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  @override
  void sendMessage(Map<String, dynamic> message) {
    final event = message['type']?.toString();
    final data = _normalizePayload(message['data']);
    if (event == null || event.isEmpty) return;

    if (_isConnected) {
      _socket?.emit(event, data);
    } else {
      _pendingMessages.add(message);
    }
  }

  Map<String, dynamic> _normalizePayload(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {'value': payload};
  }

  void _flushPendingMessages() {
    if (!_isConnected || _pendingMessages.isEmpty) return;
    final toSend = List<Map<String, dynamic>>.from(_pendingMessages);
    _pendingMessages.clear();
    for (final msg in toSend) {
      sendMessage(msg);
    }
  }

  void dispose() {
    _eventController.close();
    _socket?.dispose();
    _socket = null;
  }
}
