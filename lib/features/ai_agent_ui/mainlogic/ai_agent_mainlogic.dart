import 'package:flutter/material.dart';
import 'dart:async';
import 'package:aone_ui/core/config/app_config.dart';
import '../slavelogic/agent_chat_history_api.dart';
import '../slavelogic/agent_chat_v3_api.dart';
import '../slavelogic/agent_chat_v3_prompt.dart';
import '../slavelogic/agent_chat_v3_state.dart';
import '../slavelogic/agent_models.dart';
import '../slavelogic/trello_agent_api.dart';

part 'ai_agent_creation_logic.dart';
part 'ai_agent_selection_logic.dart';
part 'ai_agent_chat_logic.dart';
part 'ai_agent_feedback_logic.dart';
part 'ai_agent_history_logic.dart';
part 'ai_agent_task_logic.dart';
part 'ai_agent_todo_logic.dart';

class AiAgentMainlogic extends ChangeNotifier {
  final api = TrelloAgentApi();
  final historyApi = AgentChatHistoryApi();
  final chatV3 = AgentChatV3State();
  final chatText = TextEditingController();
  final projectText = TextEditingController();
  final boardText = TextEditingController();
  final taskText = TextEditingController();
  final todoText = TextEditingController();
  final messages = <AgentChatLine>[
    AgentChatLine('Master agent online. Pick a project or brief me.', false),
  ];
  final projects = <AgentProject>[];
  final boards = <AgentBoard>[];
  final tasks = <AgentTask>[];
  AgentView view = AgentView.master;
  String? error;
  String? selectedProjectId;
  String? selectedBoardId;
  bool loading = false;

  Iterable<AgentTask> laneTasks(String status) => tasks.where(
        (t) => t.status == status && t.boardId == selectedBoardId,
      );

  void pulse() => notifyListeners();

  Future<void> load() async {
    if (loading) return;
    await runBusy(() async {
      await loadChatHistory();
      projects
        ..clear()
        ..addAll(await api.projects());
      if (projects.isNotEmpty) await selectProject(projects.first.id);
    });
  }

  Future<void> runBusy(Future<void> Function() job) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await job();
    } on TimeoutException {
      error = 'API timeout. The project may still have saved; tap Refresh.';
    } catch (e) {
      error = _friendlyError(e);
    }
    loading = false;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    if (text.contains('XMLHttpRequest')) {
      return 'Browser blocked the API request. The Trello API needs CORS.';
    }
    return text;
  }

  @override
  void dispose() {
    chatText.dispose();
    chatV3.dispose();
    projectText.dispose();
    boardText.dispose();
    taskText.dispose();
    todoText.dispose();
    super.dispose();
  }
}
