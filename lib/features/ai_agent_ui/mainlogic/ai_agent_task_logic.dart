part of 'ai_agent_mainlogic.dart';

extension AiAgentTaskLogic on AiAgentMainlogic {
  Future<void> assignAgent(AgentTask task) async {
    await runBusy(() async {
      final i = tasks.indexWhere((t) => t.id == task.id);
      if (i < 0) return;
      final assignedAt = DateTime.now().toUtc();
      final activeCount = tasks.where((t) => t.hasAgent).length;
      final instance = '${AppConfig.agentModelName}-${activeCount + 1}';
      tasks[i] = task.assign(
        modelName: AppConfig.agentModelName,
        modelInstance: instance,
        assignedAt: assignedAt,
      );
      tasks[i] = await api.assignTaskAgent(
        task: task,
        modelName: AppConfig.agentModelName,
        modelInstance: instance,
        assignedAt: assignedAt,
      );
      await loadSubAgentSessions(tasks[i]);
      messages.add(
        AgentChatLine('$instance assigned to ${task.title}.', false),
      );
    });
  }

  Future<void> chatWithTask(AgentTask task) async {
    await openSubAgentTask(task);
  }

  Future<void> moveTask(AgentTask task, String status) async {
    final boardId = selectedBoardId;
    if (boardId == null) return;
    await moveTaskTo(task, boardId: boardId, status: status);
  }

  Future<void> moveTaskTo(
    AgentTask task, {
    required String boardId,
    required String status,
  }) async {
    await runBusy(() async {
      final i = tasks.indexWhere((t) => t.id == task.id);
      if (i >= 0) tasks[i] = task.withBoardAndStatus(boardId, status);
      final updated = await api.moveTask(
        task: task,
        boardId: boardId,
        status: status,
      );
      if (boardId == selectedBoardId) {
        final updatedIndex = tasks.indexWhere((t) => t.id == task.id);
        if (updatedIndex >= 0) {
          tasks[updatedIndex] = updated;
        } else {
          tasks.insert(0, updated);
        }
      } else {
        tasks.removeWhere((t) => t.id == task.id);
      }
    });
  }

  Future<void> deleteTask(AgentTask task) async {
    await runBusy(() async {
      await api.deleteTask(task.id);
      tasks.removeWhere((t) => t.id == task.id);
    });
  }

  Future<void> clearLane(String status) async {
    final doomed = laneTasks(status).toList();
    await runBusy(() async {
      for (final task in doomed) {
        await api.deleteTask(task.id);
      }
      tasks.removeWhere(
          (t) => t.status == status && t.boardId == selectedBoardId);
    });
  }

  Future<void> cancelAgent(AgentTask task) async {
    await runBusy(() async {
      final i = tasks.indexWhere((t) => t.id == task.id);
      if (i >= 0) tasks[i] = task.withoutAgent();
      final updated = await api.cancelTaskAgent(task);
      final j = tasks.indexWhere((t) => t.id == task.id);
      if (j >= 0) tasks[j] = updated;
    });
  }
}
