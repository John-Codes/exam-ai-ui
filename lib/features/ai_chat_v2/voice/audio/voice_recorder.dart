import 'dart:async';

import 'package:record/record.dart';

class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<List<int>>? _subscription;

  Future<bool> start(void Function(List<int>) sendFrame) async {
    if (!await _recorder.hasPermission()) return false;
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _subscription = stream.listen(sendFrame);
    return true;
  }

  Future<void> stop() async {
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _recorder.dispose();
  }
}
