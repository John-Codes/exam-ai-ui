import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:aone_ui/core/config/app_config.dart';

class AgentChatV3Api {
  static const _maxRetries = 0;
  static const _timeout = Duration(seconds: 180);

  static Future<Map<String, dynamic>> generateResponse({
    required String message,
    required String userMessage,
    required String sessionId,
    String? imageData,
  }) async {
    final imageError = _imageError(imageData);
    if (imageError != null) return {'success': false, 'error': imageError};
    final body = {
      'text': message,
      'user_message': userMessage,
      'api_key': AppConfig.aiChatApiKey,
      'model_name': AppConfig.agentModelName,
      'session_id': sessionId,
      if (imageData != null && imageData.isNotEmpty) 'image_data': imageData,
    };
    return _send(body);
  }

  static Future<Map<String, dynamic>> _send(Map<String, dynamic> body) async {
    for (var attempt = 1; attempt <= _maxRetries + 1; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse('${AppConfig.aiChatBaseUrl}/generate'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_timeout);
        if (res.statusCode == 200) return _ok(res.body);
        if (attempt > _maxRetries || !_retryable(res.statusCode)) {
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

  static Map<String, dynamic> _ok(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json.containsKey('response')) {
      return {
        'success': json['success'] != false && json['error'] == null,
        'response': json['response'] ?? '',
        'error': json['error'],
      };
    }
    return {'success': false, 'error': 'Unexpected response shape'};
  }

  static String? _imageError(String? data) {
    if (data == null) return null;
    try {
      if (base64Decode(data).length > 5 * 1024 * 1024) {
        return 'Image too large. Maximum size is 5MB.';
      }
    } catch (_) {
      return 'Invalid image data format';
    }
    return null;
  }

  static bool _retryable(int code) => code >= 500 || code == 429 || code == 408;
}
