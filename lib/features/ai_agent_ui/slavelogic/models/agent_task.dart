import 'agent_json.dart';
import 'agent_todo.dart';

class AgentTask {
  final String id, boardId, title, description, status;
  final int priority;
  final String? agentModelName, agentModelInstance;
  final DateTime? createdAt, updatedAt, listEnteredAt, agentAssignedAt;
  final List<AgentTodo> todos;

  const AgentTask(
    this.id,
    this.boardId,
    this.title,
    this.description,
    this.status,
    this.priority, {
    this.createdAt,
    this.updatedAt,
    this.listEnteredAt,
    this.agentModelName,
    this.agentModelInstance,
    this.agentAssignedAt,
    this.todos = const [],
  });

  String? get agent => agentModelInstance;
  bool get hasAgent => agentModelInstance != null;

  AgentTask assign({
    required String modelName,
    required String modelInstance,
    required DateTime assignedAt,
  }) =>
      _copy(
        agentModelName: modelName,
        agentModelInstance: modelInstance,
        agentAssignedAt: assignedAt,
      );

  AgentTask withStatus(String value) => _copy(status: value);

  AgentTask withBoardAndStatus(String boardId, String status) =>
      _copy(boardId: boardId, status: status);

  AgentTask withoutAgent() => AgentTask(
        id,
        boardId,
        title,
        description,
        status,
        priority,
        createdAt: createdAt,
        updatedAt: updatedAt,
        listEnteredAt: listEnteredAt,
        todos: todos,
      );

  AgentTask withTodos(List<AgentTodo> value) => _copy(todos: value);

  AgentTask _copy({
    String? boardId,
    String? status,
    String? agentModelName,
    String? agentModelInstance,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? listEnteredAt,
    DateTime? agentAssignedAt,
    List<AgentTodo>? todos,
  }) =>
      AgentTask(
        id,
        boardId ?? this.boardId,
        title,
        description,
        status ?? this.status,
        priority,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        listEnteredAt: listEnteredAt ?? this.listEnteredAt,
        agentModelName: agentModelName ?? this.agentModelName,
        agentModelInstance: agentModelInstance ?? this.agentModelInstance,
        agentAssignedAt: agentAssignedAt ?? this.agentAssignedAt,
        todos: todos ?? this.todos,
      );

  factory AgentTask.fromJson(Map<String, dynamic> json) => AgentTask(
        '${json['id'] ?? json['_id'] ?? ''}',
        '${json['board_id'] ?? ''}',
        '${json['title'] ?? 'Untitled task'}',
        '${json['description'] ?? ''}',
        '${json['status'] ?? 'todo'}',
        json['priority'] is int ? json['priority'] : 0,
        createdAt: optionalDateTime(json['created_at']),
        updatedAt: optionalDateTime(json['updated_at']),
        listEnteredAt: optionalDateTime(json['list_entered_at']),
        agentModelName: optionalString(json['agent_model_name']),
        agentModelInstance: optionalString(
          json['agent_model_instance'] ?? json['agent'],
        ),
        agentAssignedAt: optionalDateTime(json['agent_assigned_at']),
        todos: _todoList(json['todos']),
      );
}

List<AgentTodo> _todoList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => AgentTodo.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
