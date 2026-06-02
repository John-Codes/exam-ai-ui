import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';
import 'task_sheet.dart';
import 'widgets/confirm_action_dialog.dart';

class ActiveAgentsView extends StatelessWidget {
  final AiAgentMainlogic logic;
  const ActiveAgentsView({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    final active = logic.tasks.where((t) => t.hasAgent).toList();
    if (active.isEmpty)
      return const Center(child: Text('No active agents yet'));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: active.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final task = active[i];
        return ListTile(
          leading: const Icon(Icons.smart_toy_outlined),
          title: Text(task.agentModelInstance!),
          subtitle: Text(_subtitle(task), maxLines: 2),
          trailing: IconButton(
            tooltip: 'Cancel active agent',
            icon: const Icon(Icons.person_remove_outlined),
            onPressed: () => _cancelAgent(context, logic, task),
          ),
          onTap: () => showTaskSheet(context, logic, task),
        );
      },
    );
  }

  String _subtitle(AgentTask task) {
    final model = task.agentModelName ?? 'local-agent';
    final assignedAt = task.agentAssignedAt?.toLocal();
    final assigned = assignedAt == null
        ? 'not dated'
        : '${assignedAt.year.toString().padLeft(4, '0')}-'
            '${assignedAt.month.toString().padLeft(2, '0')}-'
            '${assignedAt.day.toString().padLeft(2, '0')} '
            '${assignedAt.hour.toString().padLeft(2, '0')}:'
            '${assignedAt.minute.toString().padLeft(2, '0')}';
    return '$model - $assigned - ${task.title}';
  }
}

Future<void> _cancelAgent(
  BuildContext context,
  AiAgentMainlogic logic,
  AgentTask task,
) async {
  final ok = await confirmAction(
    context,
    title: 'Cancel active agent?',
    message: 'This clears "${task.agentModelInstance}" from "${task.title}".',
    actionLabel: 'Cancel agent',
  );
  if (ok) logic.cancelAgent(task);
}
