import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/thor_voice_api.dart';
import '../audio/voice_player.dart';
import '../audio/voice_recorder.dart';
import '../text/spoken_text_cleaner.dart';
import '../websocket/thor_voice_event.dart';
import '../websocket/thor_voice_socket.dart';

export '../api/thor_voice_api.dart';
export '../audio/voice_player.dart';
export '../audio/voice_recorder.dart';
export '../websocket/thor_voice_socket.dart';

enum ThorVoiceState { idle, connecting, listening, waitingForReply, speaking }

class ThorVoiceController extends ChangeNotifier {
  ThorVoiceController(
      {required this.api,
      required this.recorder,
      required this.player,
      required this.socket,
      required this.socketUrl,
      required this.token,
      required this.onTranscript,
      required this.onSubmit,
      required this.onError});

  final ThorVoiceApi api;
  final VoiceRecorder recorder;
  final VoicePlayer player;
  final ThorVoiceSocket socket;
  final String socketUrl;
  final String token;
  final ValueChanged<String> onTranscript;
  final VoidCallback onSubmit;
  final ValueChanged<Object> onError;
  ThorVoiceState state = ThorVoiceState.idle;
  bool _enabled = false;

  Future<bool> enable() async {
    _enabled = true;
    return _startListening();
  }

  Future<bool> _startListening() async {
    if (!_enabled) return false;
    if (token.isEmpty) throw StateError('VOICE_API_TOKEN is missing.');
    _setState(ThorVoiceState.connecting);
    await socket.connect(
        url: socketUrl, token: token, onEvent: _handleEvent, onError: _fail);
    if (!_enabled) {
      await socket.close();
      return false;
    }
    final started = await recorder.start(socket.send);
    if (!started) {
      await cancel();
      return false;
    }
    _setState(ThorVoiceState.listening);
    return true;
  }

  Future<void> _handleEvent(ThorVoiceEvent event) async {
    if (event.type == ThorVoiceEventType.error) {
      return _fail(StateError(event.message));
    }
    onTranscript(event.message);
    if (event.type != ThorVoiceEventType.complete ||
        state != ThorVoiceState.listening) return;
    _setState(ThorVoiceState.waitingForReply);
    await recorder.stop();
    await socket.close();
    if (event.message.isEmpty) {
      return _fail(StateError('Thor returned an empty transcript.'));
    }
    onSubmit();
  }

  Future<void> speak(String text) async {
    if (!_enabled || state != ThorVoiceState.waitingForReply) return;
    final cleaned = cleanTextForSpeech(text);
    if (cleaned.isEmpty) return _fail(StateError('AOne returned no speech.'));
    _setState(ThorVoiceState.speaking);
    try {
      await player.play(await api.synthesize(cleaned));
      if (_enabled) await _startListening();
    } catch (error) {
      await _fail(error);
    }
  }

  Future<void> cancel() async {
    _enabled = false;
    await recorder.stop();
    await player.stop();
    await socket.close();
    _setState(ThorVoiceState.idle);
  }

  Future<void> _fail(Object error) async {
    await cancel();
    onError(error);
  }

  void _setState(ThorVoiceState next) {
    state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(cancel());
    api.dispose();
    unawaited(recorder.dispose());
    unawaited(player.dispose());
    super.dispose();
  }
}
