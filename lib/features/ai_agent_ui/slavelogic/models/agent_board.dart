class AgentBoard {
  final String id;
  final String name;
  final String description;

  const AgentBoard(this.id, this.name, this.description);

  factory AgentBoard.fromJson(Map<String, dynamic> json) => AgentBoard(
        '${json['id'] ?? json['_id'] ?? ''}',
        '${json['name'] ?? 'Board'}',
        '${json['description'] ?? ''}',
      );
}
