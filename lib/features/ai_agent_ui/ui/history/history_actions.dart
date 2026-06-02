import 'package:flutter/material.dart';
import '../../mainlogic/ai_agent_mainlogic.dart';

class HistoryActions extends StatelessWidget {
  final AiAgentMainlogic logic;
  const HistoryActions({super.key, required this.logic});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('New chat'),
          onPressed: logic.loading ? null : () => logic.newChatSession(),
        ),
      );
}
