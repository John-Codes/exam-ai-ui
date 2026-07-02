import 'dart:async';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'thor_voice_event.dart';

class ThorVoiceSocket {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _closing = false;

  Future<void> connect({
    required String url,
    required String token,
    required void Function(ThorVoiceEvent) onEvent,
    required void Function(Object) onError,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: {'token': token});
    _closing = false;
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    await channel.ready;
    _subscription = channel.stream.listen(
      (message) {
        try {
          onEvent(ThorVoiceEvent.fromMessage(message));
        } catch (_) {
          onError(const FormatException('Invalid Thor voice response'));
        }
      },
      onError: (Object error) => onError(error),
      onDone: () {
        if (!_closing) onError(StateError('Thor voice connection closed'));
      },
    );
  }

  void send(List<int> frame) => _channel?.sink.add(Uint8List.fromList(frame));

  Future<void> close() async {
    _closing = true;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
