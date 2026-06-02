import 'agent_json.dart';

class AgentTodo {
  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? doneAt;

  const AgentTodo({
    required this.id,
    required this.title,
    this.createdAt,
    this.doneAt,
  });

  bool get done => doneAt != null;

  factory AgentTodo.fromJson(Map<String, dynamic> json) => AgentTodo(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? 'Todo'}',
        createdAt: optionalDateTime(json['created_at']),
        doneAt: optionalDateTime(json['done_at']),
      );
}
