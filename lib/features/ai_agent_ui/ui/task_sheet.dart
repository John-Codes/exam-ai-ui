import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';
import 'task_age_row.dart';
import 'widgets/confirm_action_dialog.dart';

void showTaskSheet(
  BuildContext context,
  AiAgentMainlogic logic,
  AgentTask task,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => _TaskSheet(logic: logic, task: task),
  );
}

class _TaskSheet extends StatelessWidget {
  final AiAgentMainlogic logic;
  final AgentTask task;
  const _TaskSheet({required this.logic, required this.task});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: logic,
        builder: (context, _) {
          final liveTask = logic.tasks.firstWhere(
            (item) => item.id == task.id,
            orElse: () => task,
          );
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        liveTask.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete task',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Delete task?',
                          message: 'This deletes "${liveTask.title}".',
                        );
                        if (!ok || !context.mounted) return;
                        Navigator.pop(context);
                        logic.deleteTask(liveTask);
                      },
                    ),
                  ],
                ),
                if (liveTask.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(liveTask.description),
                ],
                const SizedBox(height: 8),
                TaskAgeRow(task: liveTask),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in ['todo', 'doing', 'review', 'done'])
                      ChoiceChip(
                        label: Text(s),
                        selected: liveTask.status == s,
                        onSelected: (_) {
                          Navigator.pop(context);
                          logic.moveTask(liveTask, s);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title:
                      Text(liveTask.agentModelInstance ?? 'Assign model agent'),
                  subtitle: liveTask.agentModelName == null
                      ? null
                      : Text(liveTask.agentModelName!),
                  onTap: () {
                    Navigator.pop(context);
                    logic.assignAgent(liveTask);
                  },
                ),
                if (liveTask.hasAgent)
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined),
                    title: const Text('Cancel active agent'),
                    onTap: () async {
                      final ok = await confirmAction(
                        context,
                        title: 'Cancel active agent?',
                        message:
                            'This clears the model assignment from this task.',
                        actionLabel: 'Cancel agent',
                      );
                      if (!ok || !context.mounted) return;
                      Navigator.pop(context);
                      logic.cancelAgent(liveTask);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Chat with task agent'),
                  enabled: liveTask.agent != null,
                  onTap: () {
                    Navigator.pop(context);
                    logic.chatWithTask(liveTask);
                  },
                ),
                const Divider(height: 24),
                Text('Todos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final todo in liveTask.todos)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: todo.done,
                    title: Text(todo.title),
                    secondary: IconButton(
                      tooltip: 'Delete todo',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          _deleteTodo(context, logic, liveTask, todo),
                    ),
                    onChanged: (value) =>
                        logic.toggleTodo(liveTask, todo, value ?? false),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: logic.todoText,
                        decoration: const InputDecoration(
                          labelText: 'New todo',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => logic.addTodo(liveTask),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add todo',
                      icon: const Icon(Icons.add_task_outlined),
                      onPressed: () => logic.addTodo(liveTask),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

Future<void> _deleteTodo(
  BuildContext context,
  AiAgentMainlogic logic,
  AgentTask task,
  AgentTodo todo,
) async {
  final ok = await confirmAction(
    context,
    title: 'Delete todo?',
    message: 'This deletes "${todo.title}".',
  );
  if (ok) logic.deleteTodo(task, todo);
}
