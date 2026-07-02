import 'package:flutter/material.dart';

import '../../mainlogic/ai_agent_mainlogic.dart';
import '../../slavelogic/agent_models.dart';
import 'chat_session_drawer_row.dart';
import 'master_history_drawer_button.dart';

class MasterAgentDrawerSection extends StatelessWidget {
  final AiAgentMainlogic logic;
  const MasterAgentDrawerSection({super.key, required this.logic});

  bool get _masterChatActive =>
      logic.view == AgentView.master && logic.chatV3.activeSubAgent == null;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        leading: const Icon(Icons.auto_awesome),
        title: const Text('Master Agent'),
        initiallyExpanded: _masterChatActive,
        children: [
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Open master chat'),
            selected: _masterChatActive,
            onTap: () {
              Navigator.pop(context);
              logic.openMasterChat();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_comment_outlined),
            title: const Text('New master chat'),
            onTap: logic.loading
                ? null
                : () {
                    Navigator.pop(context);
                    logic.newMasterChatSession();
                  },
          ),
          MasterHistoryDrawerButton(logic: logic),
          if (logic.chatV3.masterSessions.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent master chats'),
              ),
            ),
          for (final session in logic.chatV3.masterSessions.take(10))
            ChatSessionDrawerRow(
              session: session,
              selected: logic.chatV3.masterSessionId == session.id,
              busy: logic.loading,
              openChat: () {
                Navigator.pop(context);
                logic.openMasterChatSession(session);
              },
              deleteChat: () => logic.deleteChatSession(session),
            ),
        ],
      );
}
