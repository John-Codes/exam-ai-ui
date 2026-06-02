import 'agent_models.dart';

class AgentChatV3Prompt {
  static const _maxMessages = 40;
  static const _maxChars = 12000;

  static String build(List<AgentChatLine> messages) {
    final lines = messages
        .where((m) => !m.isLoading)
        .toList()
        .reversed
        .take(_maxMessages)
        .toList()
        .reversed
        .map(_line)
        .where((line) => line.trim().isNotEmpty)
        .join('\n\n');
    final prompt = 'You are Chat v3. Continue this conversation.\n\n$lines';
    if (prompt.length <= _maxChars) return prompt;
    return prompt.substring(prompt.length - _maxChars);
  }

  static String _line(AgentChatLine message) {
    final role = message.mine ? 'User' : 'Assistant';
    final image = message.hasImage ? '\n[Image attached]' : '';
    final text = message.text.trim();
    if (text.isEmpty && image.isEmpty) return '';
    return '$role: $text$image';
  }
}
