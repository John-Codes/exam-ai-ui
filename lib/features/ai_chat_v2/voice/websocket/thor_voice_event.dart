import 'dart:convert';

enum ThorVoiceEventType { incomplete, complete, error }

class ThorVoiceEvent {
  const ThorVoiceEvent(this.type, this.message);

  final ThorVoiceEventType type;
  final String message;

  factory ThorVoiceEvent.fromMessage(dynamic message) {
    final json = jsonDecode(message as String) as Map<String, dynamic>;
    final type = switch (json['type']) {
      'incomplete' => ThorVoiceEventType.incomplete,
      'complete' => ThorVoiceEventType.complete,
      'error' => ThorVoiceEventType.error,
      _ => throw const FormatException('Unknown Thor voice event'),
    };
    final value = type == ThorVoiceEventType.error
        ? json['message'] as String?
        : json['text'] as String?;
    return ThorVoiceEvent(type, value?.trim() ?? '');
  }
}
