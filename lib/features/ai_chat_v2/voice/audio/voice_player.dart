import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class VoicePlayer {
  final AudioPlayer _player = AudioPlayer();
  Completer<void>? _finished;
  StreamSubscription<void>? _completion;

  Future<void> play(Uint8List audio) async {
    await stop();
    _finished = Completer<void>();
    _completion = _player.onPlayerComplete.listen((_) {
      if (!(_finished?.isCompleted ?? true)) _finished?.complete();
    });
    await _player.play(BytesSource(audio));
    await _finished?.future;
    await _completion?.cancel();
    _completion = null;
  }

  Future<void> stop() async {
    await _player.stop();
    if (!(_finished?.isCompleted ?? true)) _finished?.complete();
    await _completion?.cancel();
    _completion = null;
  }

  Future<void> dispose() => _player.dispose();
}
