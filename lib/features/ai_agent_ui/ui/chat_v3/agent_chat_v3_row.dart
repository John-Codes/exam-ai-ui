import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../slavelogic/agent_models.dart';
import 'agent_chat_v3_feedback.dart';
import 'agent_chat_v3_image.dart';

class AgentChatV3Row extends StatelessWidget {
  final AgentChatLine message;
  final void Function(AgentChatLine, String) onFeedback;

  const AgentChatV3Row({
    super.key,
    required this.message,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    if (message.mine) return _UserBubble(message: message);
    return _AgentText(message: message, onFeedback: onFeedback);
  }
}

class _AgentText extends StatelessWidget {
  final AgentChatLine message;
  final void Function(AgentChatLine, String) onFeedback;
  const _AgentText({required this.message, required this.onFeedback});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(p: const TextStyle(height: 1.62, fontSize: 16)),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: message.text)),
                ),
                AgentChatV3Feedback(
                  message: message,
                  onFeedback: onFeedback,
                ),
              ],
            ),
          ],
        ),
      );
}

class _UserBubble extends StatelessWidget {
  final AgentChatLine message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 22, left: 42),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6CDF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.imageData != null) ...[
                AgentChatV3Image(data: message.imageData!, height: 150),
                if (message.text.isNotEmpty) const SizedBox(height: 8),
              ] else if (message.hasImage) ...[
                const Text('[Image attached]',
                    style: TextStyle(color: Colors.white70)),
                if (message.text.isNotEmpty) const SizedBox(height: 8),
              ],
              if (message.text.isNotEmpty)
                Text(message.text, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
}
