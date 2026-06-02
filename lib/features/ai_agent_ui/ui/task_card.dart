import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';
import 'task_age_row.dart';
import 'task_sheet.dart';
import 'widgets/confirm_action_dialog.dart';

class TaskCard extends StatelessWidget {
  final AiAgentMainlogic logic;
  final AgentTask task;
  const TaskCard({super.key, required this.logic, required this.task});

  @override
  Widget build(BuildContext context) => Draggable<AgentTask>(
        data: task,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 260,
            child: Opacity(opacity: 0.92, child: _CardBody(task: task)),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: _TaskCardShell(logic: logic, task: task),
        ),
        child: _TaskCardShell(logic: logic, task: task),
      );
}

class _TaskCardShell extends StatelessWidget {
  final AiAgentMainlogic logic;
  final AgentTask task;
  const _TaskCardShell({required this.logic, required this.task});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showTaskSheet(context, logic, task),
          child: _CardBody(
            task: task,
            trailing: IconButton(
              tooltip: 'Delete task',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteTask(context, logic, task),
            ),
          ),
        ),
      );
}

class _CardBody extends StatelessWidget {
  final AgentTask task;
  final Widget? trailing;
  const _CardBody({required this.task, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description, maxLines: 2),
            ],
            const SizedBox(height: 6),
            TaskAgeRow(task: task),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Chip(label: Text(task.status)),
                if (task.agent != null) Chip(label: Text(task.agent!)),
              ],
            ),
          ],
        ),
      );
}

Future<void> _deleteTask(
  BuildContext context,
  AiAgentMainlogic logic,
  AgentTask task,
) async {
  final ok = await confirmAction(
    context,
    title: 'Delete task?',
    message: 'This deletes "${task.title}".',
  );
  if (ok) logic.deleteTask(task);
}
