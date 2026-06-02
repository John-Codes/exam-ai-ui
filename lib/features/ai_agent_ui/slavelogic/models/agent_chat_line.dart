class AgentChatLine {
  final String? id;
  final String text;
  final bool mine;
  final DateTime timestamp;
  final String? imageData;
  final bool hasImage;
  final String? feedback;
  final bool isLoading;

  AgentChatLine(
    this.text,
    this.mine, {
    this.id,
    DateTime? timestamp,
    this.imageData,
    bool? hasImage,
    this.feedback,
    this.isLoading = false,
  })  : hasImage = hasImage ?? imageData != null,
        timestamp = timestamp ?? DateTime.now();

  AgentChatLine copyWith({String? id, bool? isLoading, String? feedback}) =>
      AgentChatLine(
        text,
        mine,
        id: id ?? this.id,
        timestamp: timestamp,
        imageData: imageData,
        hasImage: hasImage,
        feedback: feedback ?? this.feedback,
        isLoading: isLoading ?? this.isLoading,
      );

  factory AgentChatLine.fromJson(Map<String, dynamic> json) => AgentChatLine(
        '${json['text'] ?? ''}',
        json['mine'] == true,
        id: '${json['id'] ?? ''}',
        timestamp: DateTime.tryParse('${json['timestamp'] ?? ''}'),
        hasImage: json['has_image'] == true,
        feedback: json['feedback']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'mine': mine,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'has_image': hasImage,
        if (feedback != null) 'feedback': feedback,
      };
}
