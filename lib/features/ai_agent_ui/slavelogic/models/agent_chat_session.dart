class AgentChatSession {
  final String id;
  final String userId;
  final String clientId;
  final String agentType;
  final String modelName;
  final String? agentId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentChatSession({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.agentType,
    required this.modelName,
    this.agentId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgentChatSession.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse('${json['created_at'] ?? ''}');
    final updated = DateTime.tryParse('${json['updated_at'] ?? ''}');
    return AgentChatSession(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? 'local'}',
      clientId: '${json['client_id'] ?? 'local'}',
      agentType: '${json['agent_type'] ?? 'master'}',
      modelName: '${json['model_name'] ?? 'local-agent'}',
      agentId: json['agent_id']?.toString(),
      title: '${json['title'] ?? 'Chat v3'}',
      createdAt: created ?? DateTime.now(),
      updatedAt: updated ?? DateTime.now(),
    );
  }
}
