import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aone_ui/core/config/app_config.dart';
import 'agent_models.dart';

class AgentChatHistoryApi {
  static const _timeout = Duration(seconds: 12);
  String get _base => AppConfig.agentChatHistoryBaseUrl;

  Future<String> ensureSession({
    String userId = 'local',
    String clientId = 'local',
    String agentType = 'master',
    String modelName = 'local-agent',
    String? agentId,
  }) async {
    final sessions = await listSessions(
      userId: userId,
      clientId: clientId,
      agentType: agentType,
      agentId: agentId,
    );
    if (sessions.isNotEmpty) return sessions.first.id;
    return (await createSession(
      userId: userId,
      clientId: clientId,
      agentType: agentType,
      modelName: modelName,
      agentId: agentId,
    ))
        .id;
  }

  Future<List<AgentChatSession>> listSessions({
    String userId = 'local',
    String clientId = 'local',
    String agentType = 'master',
    String? agentId,
  }) async {
    final uri = Uri(
      path: '/sessions',
      queryParameters: {
        'user_id': userId,
        'client_id': clientId,
        'agent_type': agentType,
        if (agentId != null) 'agent_id': agentId,
      },
    );
    final res = await _get(uri.toString());
    final items = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    return items.map(AgentChatSession.fromJson).toList();
  }

  Future<AgentChatSession> createSession({
    String userId = 'local',
    String clientId = 'local',
    String agentType = 'master',
    String modelName = 'local-agent',
    String? agentId,
    String title = 'Master chat',
  }) async {
    final res = await _post('/sessions', {
      'user_id': userId,
      'client_id': clientId,
      'agent_type': agentType,
      'model_name': modelName,
      'agent_id': agentId,
      'title': title,
    });
    return AgentChatSession.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteSession(String sessionId) async {
    await _delete('/sessions/$sessionId');
  }

  Future<List<AgentChatLine>> messages(String sessionId) async {
    final res = await _get('/sessions/$sessionId/messages');
    final items = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    return items.map(AgentChatLine.fromJson).toList();
  }

  Future<AgentChatLine> addMessage(String sessionId, AgentChatLine line) async {
    final res = await _post('/sessions/$sessionId/messages', line.toJson());
    return AgentChatLine.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteMessage(String sessionId, String messageId) async {
    await _delete('/sessions/$sessionId/messages/$messageId');
  }

  Future<void> clearMessages(String sessionId) async {
    await _delete('/sessions/$sessionId/messages');
  }

  Future<AgentChatLine> setFeedback({
    required String sessionId,
    required String messageId,
    required String? feedback,
  }) async {
    final res = await _patch(
      '/sessions/$sessionId/messages/$messageId/feedback',
      {'feedback': feedback},
    );
    return AgentChatLine.fromJson(jsonDecode(res.body));
  }

  Future<http.Response> _get(String path) =>
      http.get(Uri.parse('$_base$path')).timeout(_timeout);

  Future<http.Response> _post(String path, Map<String, dynamic> body) => http
      .post(
        Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
      .timeout(_timeout);

  Future<http.Response> _patch(String path, Map<String, dynamic> body) => http
      .patch(
        Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
      .timeout(_timeout);

  Future<http.Response> _delete(String path) =>
      http.delete(Uri.parse('$_base$path')).timeout(_timeout);
}
