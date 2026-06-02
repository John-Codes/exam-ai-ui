import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';
import 'active_agents_view.dart';
import 'agent_drawer.dart';
import 'chat_v3/agent_chat_v3_panel.dart';
import 'history_view.dart';
import 'projects_view.dart';

class AiAgentScreen extends StatefulWidget {
  const AiAgentScreen({super.key});

  @override
  State<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends State<AiAgentScreen> {
  late final AiAgentMainlogic logic;

  @override
  void initState() {
    super.initState();
    logic = AiAgentMainlogic()..addListener(() => setState(() {}));
    logic.load();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: logic.load,
            ),
          ],
        ),
        drawer: AgentDrawer(logic: logic),
        body: Stack(
          children: [
            _body,
            if (logic.error != null) _ErrorBanner(logic: logic),
          ],
        ),
      );

  String get _title => switch (logic.view) {
        AgentView.master => 'Chat v3',
        AgentView.projects => 'Projects',
        AgentView.agents => 'Active Agents',
        AgentView.history => logic.chatV3.showingSubAgentHistory
            ? 'Sub Agent History'
            : 'Chat History',
      };

  Widget get _body => switch (logic.view) {
        AgentView.master => AgentChatV3Panel(logic: logic),
        AgentView.projects => ProjectsView(logic: logic),
        AgentView.agents => ActiveAgentsView(logic: logic),
        AgentView.history => HistoryView(logic: logic),
      };
}

class _ErrorBanner extends StatelessWidget {
  final AiAgentMainlogic logic;
  const _ErrorBanner({required this.logic});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: MaterialBanner(
          content: Text(logic.error!),
          actions: [
            TextButton(onPressed: logic.load, child: const Text('Retry')),
          ],
        ),
      );
}
