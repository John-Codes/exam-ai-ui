import 'package:flutter/material.dart';

import '../../mainlogic/ai_agent_mainlogic.dart';
import '../../slavelogic/agent_models.dart';

class MasterHistoryDrawerButton extends StatelessWidget {
  final AiAgentMainlogic logic;
  const MasterHistoryDrawerButton({super.key, required this.logic});

  bool get _showingMasterHistory =>
      logic.view == AgentView.history && !logic.chatV3.showingSubAgentHistory;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.history),
        title: const Text('View all master history'),
        selected: _showingMasterHistory,
        onTap: logic.loading
            ? null
            : () {
                Navigator.pop(context);
                logic.openMasterHistory();
              },
      );
}
