class AgentProject {
  final String id;
  final String name;
  final String description;

  const AgentProject(this.id, this.name, this.description);

  factory AgentProject.fromJson(Map<String, dynamic> json) => AgentProject(
        '${json['id'] ?? json['_id'] ?? ''}',
        '${json['name'] ?? 'Untitled project'}',
        '${json['description'] ?? ''}',
      );
}
