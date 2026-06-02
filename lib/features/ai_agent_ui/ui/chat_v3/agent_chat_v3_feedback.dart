import 'package:flutter/material.dart';
import '../../slavelogic/agent_models.dart';

class AgentChatV3Feedback extends StatelessWidget {
  final AgentChatLine message;
  final void Function(AgentChatLine, String) onFeedback;

  const AgentChatV3Feedback({
    super.key,
    required this.message,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Button(
            icon: Icons.thumb_up_alt_outlined,
            active: message.feedback == 'like',
            onPressed: () => onFeedback(message, 'like'),
          ),
          _Button(
            icon: Icons.thumb_down_alt_outlined,
            active: message.feedback == 'dislike',
            onPressed: () => onFeedback(message, 'dislike'),
          ),
        ],
      );
}

class _Button extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;
  const _Button({
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 18),
        color: active ? Theme.of(context).colorScheme.primary : null,
        onPressed: onPressed,
      );
}
