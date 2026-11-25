import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/models/leap_event.dart';

class LeapWebSocketService {
  final String url;
  WebSocketChannel? _channel;
  final _controller = StreamController<LeapEvent>.broadcast();
  bool _isDisposed = false;

  LeapWebSocketService({this.url = 'ws://127.0.0.1:8765'});

  Stream<LeapEvent> get events => _controller.stream;

  void connect() {
    if (_isDisposed) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        _handleMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    final map = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = map['type'] as String?;

    if (type == 'tracking') {
      _controller.add(
        LeapHandTracking(
          isHandDetected: map['handDetected'] as bool? ?? false,
          normalizedX: (map['x'] as num?)?.toDouble() ?? 0.5,
          normalizedY: (map['y'] as num?)?.toDouble() ?? 0.5,
          gestureProgress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    } else if (type == 'gesture') {
      final name = map['gesture'] as String?;
      final parsed = LeapGestureType.values
          .where((g) => g.name == name)
          .firstOrNull;
      if (parsed != null) {
        _controller.add(LeapGestureDetected(parsed));
      }
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _controller.add(const LeapHandTracking(isHandDetected: false));
    Future.delayed(const Duration(seconds: 2), connect);
  }

  void dispose() {
    _isDisposed = true;
    _channel?.sink.close();
    _controller.close();
  }
}
