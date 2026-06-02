import 'package:flutter/material.dart';
import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';
import 'board_lane.dart';
import 'project_pickers.dart';
import 'quick_add_sheet.dart';
import 'widgets/confirm_action_dialog.dart';

class ProjectsView extends StatelessWidget {
  final AiAgentMainlogic logic;
  const ProjectsView({super.key, required this.logic});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Pickers(logic: logic),
          _BoardToolbar(logic: logic),
          if (logic.boards.isEmpty)
            Expanded(
              child: Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create board'),
                  onPressed: () => showAddSheet(
                      context, 'Board', logic.boardText, logic.createBoard),
                ),
              ),
            )
          else
            Expanded(child: _Kanban(logic: logic)),
        ],
      );
}

class _BoardToolbar extends StatelessWidget {
  final AiAgentMainlogic logic;
  const _BoardToolbar({required this.logic});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          children: [
            for (final board in logic.boards)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DragTarget<AgentTask>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.boardId != board.id,
                  onAcceptWithDetails: (details) => logic.moveTaskTo(
                    details.data,
                    boardId: board.id,
                    status: details.data.status,
                  ),
                  builder: (context, candidate, _) {
                    final selected = logic.selectedBoardId == board.id;
                    return InputChip(
                      avatar: Icon(
                        candidate.isEmpty
                            ? Icons.view_kanban_outlined
                            : Icons.move_down_outlined,
                        size: 18,
                      ),
                      label: Text(board.name),
                      selected: selected,
                      onSelected: (_) => logic.selectBoard(board.id),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _deleteBoard(context, logic, board),
                    );
                  },
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.add),
              label: const Text('Board'),
              onPressed: () => showAddSheet(
                context,
                'Board',
                logic.boardText,
                logic.createBoard,
              ),
            ),
          ],
        ),
      );
}

Future<void> _deleteBoard(
  BuildContext context,
  AiAgentMainlogic logic,
  AgentBoard board,
) async {
  final ok = await confirmAction(
    context,
    title: 'Delete board?',
    message: 'This deletes "${board.name}" and its tasks.',
  );
  if (ok) logic.deleteBoard(board);
}

class _Kanban extends StatelessWidget {
  final AiAgentMainlogic logic;
  const _Kanban({required this.logic});

  static const statuses = ['todo', 'doing', 'review', 'done'];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final status in statuses)
                  Expanded(child: BoardLane(logic: logic, status: status)),
              ],
            );
          }
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            children: [
              for (final status in statuses)
                SizedBox(
                  width: 290,
                  child: BoardLane(logic: logic, status: status),
                ),
            ],
          );
        },
      );
}
