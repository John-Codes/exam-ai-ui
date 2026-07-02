import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ThorVoiceApi {
  ThorVoiceApi(
      {required this.baseUrl, required this.token, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  Future<Uint8List> synthesize(String text) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/synthesize'),
      headers: {
        'X-Voice-Token': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Thor Voice API failed (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  void dispose() => _client.close();
}
