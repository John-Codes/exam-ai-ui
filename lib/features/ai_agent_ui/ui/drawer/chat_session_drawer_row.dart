import 'package:flutter/material.dart';

import '../../slavelogic/agent_models.dart';
import 'delete_chat_button.dart';

class ChatSessionDrawerRow extends StatelessWidget {
  final AgentChatSession session;
  final bool selected;
  final bool busy;
  final VoidCallback openChat;
  final Future<void> Function() deleteChat;

  const ChatSessionDrawerRow({super.key, required this.session,
    required this.selected, required this.busy, required this.openChat,
    required this.deleteChat});

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 56, right: 4),
        leading: Icon(selected ? Icons.history_toggle_off : Icons.history),
        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: selected,
        onTap: busy ? null : openChat,
        trailing: DeleteChatButton(
          title: session.title,
          disabled: busy,
          deleteChat: deleteChat,
        ),
      );
}
