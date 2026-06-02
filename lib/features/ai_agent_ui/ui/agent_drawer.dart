import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';

class AgentDrawer extends StatelessWidget {
  final AiAgentMainlogic logic;
  const AgentDrawer({super.key, required this.logic});

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const ListTile(
                leading: Icon(Icons.hub_outlined),
                title: Text('AI Agent UI'),
                subtitle: Text('Mobile project workspace'),
              ),
              const Divider(),
              _Item(Icons.view_kanban_outlined, 'Projects', AgentView.projects,
                  logic),
              _MasterSection(logic: logic),
              _SubAgentsSection(logic: logic),
            ],
          ),
        ),
      );
}

class _MasterSection extends StatelessWidget {
  final AiAgentMainlogic logic;
  const _MasterSection({required this.logic});

  @override
  Widget build(BuildContext context) => ExpansionTile(
        leading: const Icon(Icons.auto_awesome),
        title: const Text('Master Agent'),
        initiallyExpanded: logic.view == AgentView.master &&
            logic.chatV3.activeSubAgent == null,
        children: [
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Open master chat'),
            selected: logic.view == AgentView.master &&
                logic.chatV3.activeSubAgent == null,
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
          for (final session in logic.chatV3.masterSessions.take(10))
            _SessionRow(
              title: session.title,
              selected: logic.chatV3.masterSessionId == session.id,
              onTap: () {
                Navigator.pop(context);
                logic.openMasterChatSession(session);
              },
            ),
          if (logic.chatV3.masterSessions.length > 10)
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View all master history'),
              onTap: () {
                Navigator.pop(context);
                logic.openMasterHistory();
              },
            ),
        ],
      );
}

class _SubAgentsSection extends StatelessWidget {
  final AiAgentMainlogic logic;
  const _SubAgentsSection({required this.logic});

  @override
  Widget build(BuildContext context) {
    final active = logic.tasks.where((t) => t.hasAgent).toList();
    final history = logic.chatV3.allSubAgentSessions;
    return ExpansionTile(
      leading: const Icon(Icons.smart_toy_outlined),
      title: const Text('Sub Agents'),
      initiallyExpanded:
          logic.view == AgentView.agents || logic.chatV3.activeSubAgent != null,
      children: [
        const _SectionLabel('Active Sub Agents'),
        for (final task in active.take(10))
          _SubAgentRow(
            task: task,
            selected: logic.chatV3.activeSubAgent?.id == task.id,
            onTap: () {
              Navigator.pop(context);
              logic.openSubAgentTask(task);
            },
          ),
        if (active.isEmpty)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('No active sub agents yet'),
          ),
        ListTile(
          leading: const Icon(Icons.list_alt_outlined),
          title: const Text('See all active sub agents'),
          onTap: () {
            Navigator.pop(context);
            logic.setView(AgentView.agents);
          },
        ),
        const Divider(height: 12),
        const _SectionLabel('Sub Agent Chat History'),
        for (final session in history.take(10))
          _SessionRow(
            title: session.title,
            selected: logic.chatV3.subSessionId == session.id,
            onTap: () {
              Navigator.pop(context);
              logic.openChatSession(session);
            },
          ),
        if (history.isEmpty)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('No sub agent history yet'),
          ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('See full sub agent history'),
          onTap: () {
            Navigator.pop(context);
            logic.openAllSubAgentHistory();
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      );
}

class _SubAgentRow extends StatelessWidget {
  final AgentTask task;
  final bool selected;
  final VoidCallback onTap;
  const _SubAgentRow({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: const Icon(Icons.smart_toy_outlined),
        title: Text(task.agentModelInstance ?? task.title, maxLines: 1),
        subtitle: Text(task.title, maxLines: 1),
        selected: selected,
        onTap: onTap,
      );
}

class _SessionRow extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _SessionRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 72, right: 12),
        leading: Icon(selected ? Icons.history_toggle_off : Icons.history),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: selected,
        onTap: onTap,
      );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final AgentView view;
  final AiAgentMainlogic logic;

  const _Item(this.icon, this.label, this.view, this.logic);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: logic.view == view,
        onTap: () {
          Navigator.pop(context);
          logic.setView(view);
        },
      );
}
