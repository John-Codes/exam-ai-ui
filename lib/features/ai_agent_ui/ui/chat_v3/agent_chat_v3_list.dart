import 'package:flutter/material.dart';
import '../../slavelogic/agent_models.dart';
import 'agent_chat_v3_row.dart';

class AgentChatV3List extends StatelessWidget {
  final List<AgentChatLine> messages;
  final void Function(AgentChatLine, String) onFeedback;

  const AgentChatV3List({
    super.key,
    required this.messages,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 640 ? 16.0 : 28.0;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(pad, 18, pad, 28),
      itemCount: messages.length,
      itemBuilder: (_, i) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: AgentChatV3Row(
            message: messages[i],
            onFeedback: onFeedback,
          ),
        ),
      ),
    );
  }
}
