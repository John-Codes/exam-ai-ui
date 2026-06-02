import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';
import 'quick_add_sheet.dart';
import 'task_card.dart';

class BoardLane extends StatelessWidget {
  final AiAgentMainlogic logic;
  final String status;
  const BoardLane({super.key, required this.logic, required this.status});

  @override
  Widget build(BuildContext context) {
    final tasks = logic.laneTasks(status).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
      child: DragTarget<AgentTask>(
        onWillAcceptWithDetails: (details) =>
            details.data.status != status ||
            details.data.boardId != logic.selectedBoardId,
        onAcceptWithDetails: (details) => logic.moveTask(details.data, status),
        builder: (context, candidate, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: candidate.isEmpty
                ? const Color(0xFF1E1E1E)
                : const Color(0xFF263329),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: candidate.isEmpty
                  ? const Color(0xFF333333)
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: ListTile(
                  dense: true,
                  title: Text(_title(status)),
                  subtitle: Text('${tasks.length}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'New task',
                        icon: const Icon(Icons.add),
                        onPressed: () => showAddSheet(
                          context,
                          'Task',
                          logic.taskText,
                          () => logic.createTask(status),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'List actions',
                        onSelected: (value) async {
                          if (value != 'clear') return;
                          final ok = await _confirm(
                            context,
                            'Clear ${_title(status)}?',
                            'This deletes every task in this list.',
                          );
                          if (ok) logic.clearLane(status);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'clear',
                            child: Text('Clear list'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => TaskCard(logic: logic, task: tasks[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(String value) =>
      {
        'todo': 'To Do',
        'doing': 'Doing',
        'review': 'Review',
        'done': 'Done'
      }[value] ??
      value;
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}
