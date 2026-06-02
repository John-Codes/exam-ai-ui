import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import 'history/history_actions.dart';
import 'history/session_tile.dart';

class HistoryView extends StatelessWidget {
  final AiAgentMainlogic logic;
  const HistoryView({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    if (logic.chatV3.historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (logic.chatV3.sessions.isEmpty) {
      return _EmptyHistory(subAgent: logic.chatV3.showingSubAgentHistory);
    }
    return Column(
      children: [
        if (!logic.chatV3.showingSubAgentHistory) HistoryActions(logic: logic),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logic.chatV3.sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => SessionTile(
              session: logic.chatV3.sessions[i],
              active: logic.chatV3.sessionId == logic.chatV3.sessions[i].id,
              busy: logic.loading,
              onOpen: () => logic.openChatSession(logic.chatV3.sessions[i]),
              onDelete: () => logic.deleteChatSession(logic.chatV3.sessions[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final bool subAgent;
  const _EmptyHistory({required this.subAgent});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
            subAgent ? 'No sub agent history yet' : 'No conversations yet'),
      );
}
