import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aone_ui/core/config/app_config.dart';

class AgentChatV3Api {
  static const _maxRetries = 2;
  static const _timeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> generateResponse({
    required String message,
    String? imageData,
  }) async {
    final imageError = _imageError(imageData);
    if (imageError != null) return {'success': false, 'error': imageError};
    final prefs = await SharedPreferences.getInstance();
    final body = {
      'text': message,
      'api_key': prefs.getString('apiKey') ?? '',
      'model_name': prefs.getString('modelName') ?? '',
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
      return {'success': true, 'response': json['response'] ?? ''};
    }
    return {'success': false, 'error': 'Unexpected response: $body'};
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
