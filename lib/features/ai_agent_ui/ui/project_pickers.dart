import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import 'quick_add_sheet.dart';
import 'widgets/confirm_action_dialog.dart';

class Pickers extends StatelessWidget {
  final AiAgentMainlogic logic;
  const Pickers({super.key, required this.logic});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          children: [
            _ProjectRow(logic: logic),
          ],
        ),
      );
}

class _ProjectRow extends StatelessWidget {
  final AiAgentMainlogic logic;
  const _ProjectRow({required this.logic});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: logic.selectedProjectId,
              items: [
                for (final p in logic.projects)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => v == null ? null : logic.selectProject(v),
              decoration: const InputDecoration(labelText: 'Project'),
            ),
          ),
          IconButton(
            tooltip: 'New project',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => showAddSheet(
              context,
              'Project',
              logic.projectText,
              logic.createProject,
            ),
          ),
          IconButton(
            tooltip: 'Delete project',
            icon: const Icon(Icons.delete_outline),
            onPressed: logic.selectedProject == null
                ? null
                : () async {
                    final project = logic.selectedProject!;
                    final ok = await confirmAction(
                      context,
                      title: 'Delete project?',
                      message:
                          'This deletes "${project.name}" plus its boards and tasks.',
                    );
                    if (ok) logic.deleteProject(project);
                  },
          ),
        ],
      );
}
