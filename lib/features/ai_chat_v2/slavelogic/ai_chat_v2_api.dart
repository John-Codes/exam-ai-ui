import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aone_ui/core/config/app_config.dart';

class AiChatV2Api {
  static const _maxRetries = 2;
  static const _timeout = Duration(seconds: 30);

  static const _appContext =
      '[You are the AOne UI assistant, focused on agentic workflows, task boards, '
      'project organization, chat sessions, and active AI agents. Help the user '
      'plan, create, review, and coordinate agent work clearly and concisely.]\n\n'
      'User question: ';

  static Future<Map<String, dynamic>> generateResponse({
    required String message,
    String? imageData,
  }) async {
    if (imageData != null) {
      if (!_isValidBase64(imageData)) {
        return {'success': false, 'error': 'Invalid image data format'};
      }
      if (base64Decode(imageData).length > 5 * 1024 * 1024) {
        return {
          'success': false,
          'error': 'Image too large. Maximum size is 5MB.'
        };
      }
    }

    final body = <String, dynamic>{
      'text': _appContext + message,
      'api_key': AppConfig.aiChatApiKey,
      'model_name': AppConfig.agentModelName,
      if (imageData != null && imageData.isNotEmpty) 'image_data': imageData,
    };

    for (var attempt = 1; attempt <= _maxRetries + 1; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse('${AppConfig.aiChatBaseUrl}/generate'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          if (json.containsKey('response')) {
            return {'success': true, 'response': json['response'] ?? ''};
          }
          return {
            'success': false,
            'error': 'Unexpected response: ${res.body}'
          };
        }

        if (attempt > _maxRetries || !_isRetryable(res.statusCode)) {
          return {
            'success': false,
            'error': 'HTTP ${res.statusCode}: ${res.body}'
          };
        }
      } catch (e) {
        if (attempt > _maxRetries) {
          return {'success': false, 'error': 'Connection error: $e'};
        }
      }
      await Future.delayed(Duration(seconds: attempt * 2));
    }
    return {'success': false, 'error': 'All retry attempts failed'};
  }

  static bool _isValidBase64(String data) {
    try {
      base64Decode(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _isRetryable(int code) =>
      code >= 500 || code == 429 || code == 408;
}
