part of 'ai_agent_mainlogic.dart';

extension AiAgentCreationLogic on AiAgentMainlogic {
  Future<void> createProject() async {
    final name = projectText.text.trim();
    if (name.isEmpty) return;
    projectText.clear();
    await runBusy(() async {
      final project = await api.createProject(name);
      projects.insert(0, project);
      selectedProjectId = project.id;
      selectedBoardId = null;
      boards.clear();
      tasks.clear();
    });
  }

  Future<void> createBoard() async {
    final name = boardText.text.trim();
    final projectId = selectedProjectId;
    if (name.isEmpty || projectId == null) return;
    boardText.clear();
    await runBusy(() async {
      final board = await api.createBoard(projectId, name);
      boards.insert(0, board);
      selectedBoardId = board.id;
      tasks.clear();
    });
  }

  Future<void> createTask(String status) async {
    final title = taskText.text.trim();
    final boardId = selectedBoardId;
    if (title.isEmpty || boardId == null) return;
    taskText.clear();
    await runBusy(() async {
      tasks.insert(0, await api.createTask(boardId, title, status));
    });
  }

  Future<void> deleteProject(AgentProject project) async {
    await runBusy(() async {
      await api.deleteProject(project.id);
      projects.removeWhere((p) => p.id == project.id);
      if (selectedProjectId == project.id) {
        boards.clear();
        tasks.clear();
        selectedProjectId = projects.isEmpty ? null : projects.first.id;
        selectedBoardId = null;
        if (selectedProjectId != null) {
          await selectProject(selectedProjectId!);
        }
      }
    });
  }

  Future<void> deleteBoard(AgentBoard board) async {
    await runBusy(() async {
      await api.deleteBoard(board.id);
      boards.removeWhere((b) => b.id == board.id);
      if (selectedBoardId == board.id) {
        tasks.clear();
        selectedBoardId = boards.isEmpty ? null : boards.first.id;
        if (selectedBoardId != null) {
          tasks.addAll(await api.tasks(selectedBoardId!));
        }
      }
    });
  }
}
