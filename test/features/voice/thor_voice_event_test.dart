import 'package:aone_ui/features/ai_chat_v2/voice/websocket/thor_voice_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses incomplete transcript', () {
    final event = ThorVoiceEvent.fromMessage(
      '{"type":"incomplete","text":"hello"}',
    );
    expect(event.type, ThorVoiceEventType.incomplete);
    expect(event.message, 'hello');
  });

  test('parses complete transcript', () {
    final event = ThorVoiceEvent.fromMessage(
      '{"type":"complete","text":"send this"}',
    );
    expect(event.type, ThorVoiceEventType.complete);
    expect(event.message, 'send this');
  });

  test('parses server error', () {
    final event = ThorVoiceEvent.fromMessage(
      '{"type":"error","message":"bad audio"}',
    );
    expect(event.type, ThorVoiceEventType.error);
    expect(event.message, 'bad audio');
  });
}
