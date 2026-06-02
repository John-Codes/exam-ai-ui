import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:aone_ui/core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'agent_models.dart';

class TrelloAgentApi {
  static const _timeout = Duration(seconds: 20);

  Future<List<AgentProject>> projects() async {
    final json = await _get('/projects?limit=100');
    return _list(json).map((e) => AgentProject.fromJson(e)).toList();
  }

  Future<AgentProject> createProject(String name) async {
    final json = await _post('/projects', {'name': name});
    return AgentProject.fromJson(json);
  }

  Future<void> deleteProject(String projectId) async {
    await _delete('/projects/$projectId');
  }

  Future<List<AgentBoard>> boards(String projectId) async {
    final boardsJson = await _get('/boards?project_id=$projectId&limit=100');
    return _list(boardsJson).map((e) => AgentBoard.fromJson(e)).toList();
  }

  Future<AgentBoard> createBoard(String projectId, String name) async {
    final json =
        await _post('/boards', {'project_id': projectId, 'name': name});
    return AgentBoard.fromJson(json);
  }

  Future<void> deleteBoard(String boardId) async {
    await _delete('/boards/$boardId');
  }

  Future<List<AgentTask>> tasks(String boardId) async {
    final json = await _get('/tasks?board_id=$boardId&limit=200');
    return _list(json).map((e) => AgentTask.fromJson(e)).toList();
  }

  Future<AgentTask> createTask(
      String boardId, String title, String status) async {
    final json = await _post('/tasks', {
      'board_id': boardId,
      'title': title,
      'status': status,
    });
    return AgentTask.fromJson(json);
  }

  Future<void> deleteTask(String taskId) async {
    await _delete('/tasks/$taskId');
  }

  Future<AgentTask> updateTask(AgentTask task, String status) async {
    final json = await _patch('/tasks/${task.id}', {'status': status});
    return AgentTask.fromJson(json);
  }

  Future<AgentTask> moveTask({
    required AgentTask task,
    required String boardId,
    required String status,
  }) async {
    final json = await _patch('/tasks/${task.id}', {
      'board_id': boardId,
      'status': status,
    });
    return AgentTask.fromJson(json);
  }

  Future<AgentTask> assignTaskAgent({
    required AgentTask task,
    required String modelName,
    required String modelInstance,
    required DateTime assignedAt,
  }) async {
    final json = await _patch('/tasks/${task.id}', {
      'agent_model_name': modelName,
      'agent_model_instance': modelInstance,
      'agent_assigned_at': assignedAt.toUtc().toIso8601String(),
    });
    return AgentTask.fromJson(json);
  }

  Future<AgentTask> cancelTaskAgent(AgentTask task) async {
    final json = await _patch('/tasks/${task.id}', {
      'agent_model_name': null,
      'agent_model_instance': null,
      'agent_assigned_at': null,
    });
    return AgentTask.fromJson(json);
  }

  Future<AgentTodo> addTodo(AgentTask task, String title) async {
    final json = await _post('/tasks/${task.id}/todos', {'title': title});
    return AgentTodo.fromJson(json);
  }

  Future<AgentTodo> updateTodo(
    AgentTask task,
    AgentTodo todo, {
    bool? done,
    String? title,
  }) async {
    final body = <String, dynamic>{};
    if (done != null) body['done'] = done;
    if (title != null) body['title'] = title;
    final json = await _patch('/tasks/${task.id}/todos/${todo.id}', body);
    return AgentTodo.fromJson(json);
  }

  Future<void> deleteTodo(AgentTask task, AgentTodo todo) async {
    await _delete('/tasks/${task.id}/todos/${todo.id}');
  }

  Future<dynamic> _get(String path) async {
    return _send(
      method: 'GET',
      path: path,
      expectedStatus: 200,
      request: () => http.get(Uri.parse('$baseUrl$path'), headers: _headers),
    );
  }

  String get baseUrl => AppConfig.trelloCloneBaseUrl;

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    return _send(
      method: 'POST',
      path: path,
      expectedStatus: 201,
      body: body,
      request: () => http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    return _send(
      method: 'PATCH',
      path: path,
      expectedStatus: 200,
      body: body,
      request: () => http.patch(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<void> _delete(String path) async {
    await _send(
      method: 'DELETE',
      path: path,
      expectedStatus: 204,
      request: () => http.delete(Uri.parse('$baseUrl$path'), headers: _headers),
    );
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (AppConfig.trelloCloneApiKey.isNotEmpty) {
      headers['x-api-key'] = AppConfig.trelloCloneApiKey;
    }
    return headers;
  }

  List<Map<String, dynamic>> _list(dynamic json) {
    final raw = json is List ? json : json['items'] ?? json['data'] ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    required int expectedStatus,
    required Future<http.Response> Function() request,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final sw = Stopwatch()..start();
    _logStart(method, uri, body);
    try {
      final res = await request().timeout(
        _timeout,
        onTimeout: () => throw TimeoutException(path),
      );
      _logResponse(method, path, res, sw.elapsedMilliseconds);
      if (res.statusCode != expectedStatus) throw Exception(_error(res));
      if (res.body.trim().isEmpty) return null;
      return jsonDecode(res.body);
    } on TimeoutException catch (e) {
      _logFailure(method, path, sw.elapsedMilliseconds, 'timeout', e);
      rethrow;
    } on http.ClientException catch (e) {
      _logFailure(method, path, sw.elapsedMilliseconds, 'client', e);
      throw Exception(_friendlyClientError(e));
    } on FormatException catch (e) {
      _logFailure(method, path, sw.elapsedMilliseconds, 'json', e);
      throw Exception('Trello API returned invalid JSON for $method $path.');
    } catch (e) {
      _logFailure(method, path, sw.elapsedMilliseconds, 'error', e);
      rethrow;
    }
  }

  String _error(http.Response res) {
    try {
      final json = jsonDecode(res.body);
      final detail = json['detail'];
      final code = detail is Map ? detail['error'] : null;
      if (res.statusCode == 429 || code == 'upstream_store_error') {
        return 'Trello API upstream rate limit. Render/Mongo returned ${res.statusCode}; try again in a moment.';
      }
      if (res.statusCode == 401) {
        return 'Trello API key was rejected.';
      }
      return code ?? detail ?? res.body;
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }

  String _friendlyClientError(http.ClientException e) {
    final text = e.message;
    if (text.contains('XMLHttpRequest') || text.contains('Failed to fetch')) {
      return 'Browser blocked or could not reach the Trello API. Check CORS and that the local API is running on $baseUrl.';
    }
    return 'Could not reach Trello API at $baseUrl: $text';
  }

  void _logStart(String method, Uri uri, Map<String, dynamic>? body) {
    if (!kDebugMode) return;
    debugPrint(
      '[TrelloAgentApi] -> $method $uri timeout=${_timeout.inSeconds}s apiKey=${AppConfig.trelloCloneApiKey.isNotEmpty} body=${_preview(body)}',
      wrapWidth: 1024,
    );
  }

  void _logResponse(
    String method,
    String path,
    http.Response res,
    int durationMs,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      '[TrelloAgentApi] <- $method $path status=${res.statusCode} duration_ms=$durationMs request_id=${res.headers['x-request-id'] ?? '-'} body=${_bodyPreview(res.body)}',
      wrapWidth: 1024,
    );
  }

  void _logFailure(
    String method,
    String path,
    int durationMs,
    String kind,
    Object error,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      '[TrelloAgentApi] !! $method $path kind=$kind duration_ms=$durationMs error=$error base=$baseUrl',
      wrapWidth: 1024,
    );
  }

  String _preview(Map<String, dynamic>? body) =>
      body == null ? '-' : _bodyPreview(jsonEncode(body));

  String _bodyPreview(String body) {
    final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 600) return compact;
    return '${compact.substring(0, 600)}...';
  }
}
