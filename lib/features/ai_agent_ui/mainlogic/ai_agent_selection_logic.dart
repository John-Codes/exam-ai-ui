part of 'ai_agent_mainlogic.dart';

extension AiAgentSelectionLogic on AiAgentMainlogic {
  AgentProject? get selectedProject {
    for (final p in projects) {
      if (p.id == selectedProjectId) return p;
    }
    return null;
  }

  AgentBoard? get selectedBoard {
    for (final b in boards) {
      if (b.id == selectedBoardId) return b;
    }
    return null;
  }

  void setView(AgentView value) {
    view = value;
    pulse();
  }

  Future<void> selectProject(String id) async {
    await runBusy(() async {
      selectedProjectId = id;
      selectedBoardId = null;
      tasks.clear();
      boards
        ..clear()
        ..addAll(await api.boards(id));
      if (boards.isNotEmpty) {
        selectedBoardId = boards.first.id;
        tasks.addAll(await api.tasks(boards.first.id));
        await loadActiveAgentHistories();
      }
    });
  }

  Future<void> selectBoard(String id) async {
    await runBusy(() async {
      selectedBoardId = id;
      tasks
        ..clear()
        ..addAll(await api.tasks(id));
      await loadActiveAgentHistories();
    });
  }

  void previewBoard(String id) {
    selectedBoardId = id;
    tasks.clear();
    pulse();
  }
}
