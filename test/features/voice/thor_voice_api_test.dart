import 'dart:convert';

import 'package:aone_ui/features/ai_chat_v2/voice/api/thor_voice_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('synthesis sends token and text then returns WAV bytes', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response.bytes([82, 73, 70, 70], 200);
    });
    final api = ThorVoiceApi(
      baseUrl: 'http://thor.test',
      token: 'secret',
      client: client,
    );

    final audio = await api.synthesize('AOne response');

    expect(captured.url.path, '/v1/synthesize');
    expect(captured.headers['X-Voice-Token'], 'secret');
    expect(jsonDecode(captured.body), {'text': 'AOne response'});
    expect(audio, [82, 73, 70, 70]);
  });
}
