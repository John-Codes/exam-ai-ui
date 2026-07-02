part of 'ai_agent_mainlogic.dart';

extension AiAgentHistoryLogic on AiAgentMainlogic {
  static const localUserId = 'local';
  static const localClientId = 'local';

  Future<void> loadChatHistory() async {
    try {
      chatV3.historyLoading = true;
      chatV3.masterSessions
        ..clear()
        ..addAll(await _listMasterSessions());
      if (AppConfig.showSubAgentUi) await loadAllSubAgentHistory();
      if (chatV3.masterSessions.isEmpty) await newMasterChatSession();
      if (chatV3.masterSessions.isNotEmpty) {
        await openMasterChatSession(chatV3.masterSessions.first);
      }
    } catch (e) {
      error = 'Chat history API unavailable: $e';
    } finally {
      chatV3.historyLoading = false;
    }
  }

  Future<void> newChatSession() async {
    if (AppConfig.showSubAgentUi &&
        chatV3.activeChatIsSub &&
        chatV3.activeSubAgent != null) {
      await openSubAgentTask(chatV3.activeSubAgent!);
      return;
    }
    await newMasterChatSession();
  }

  Future<void> newMasterChatSession() async {
    final session = await historyApi.createSession(
      userId: localUserId,
      clientId: localClientId,
      agentType: 'master',
      modelName: AppConfig.agentModelName,
      title: 'Master chat',
    );
    chatV3.activeSubAgent = null;
    chatV3.activeChatIsSub = false;
    chatV3.showingSubAgentHistory = false;
    chatV3.masterSessions.insert(0, session);
    chatV3.sessionId = session.id;
    view = AgentView.master;
    _resetChatGreeting();
    pulse();
  }

  Future<void> refreshChatSessions() async {
    try {
      if (AppConfig.showSubAgentUi && chatV3.showingSubAgentHistory) {
        await loadAllSubAgentHistory();
      } else if (!chatV3.activeChatIsSub) {
        chatV3.masterSessions
          ..clear()
          ..addAll(await _listMasterSessions());
      } else if (AppConfig.showSubAgentUi && chatV3.activeSubAgent != null) {
        await loadSubAgentSessions(chatV3.activeSubAgent!);
        await loadAllSubAgentHistory();
      }
    } catch (_) {}
  }

  Future<void> openChatSession(AgentChatSession session) async {
    if (session.agentType == 'sub') {
      if (!AppConfig.showSubAgentUi) return;
      final task = _taskForSession(session);
      if (task != null) {
        await openSubAgentChatSession(task, session);
        return;
      }
      await openStoredSubAgentSession(session);
      return;
    }
    await openMasterChatSession(session);
  }

  Future<void> openMasterChat() async {
    chatV3.activeSubAgent = null;
    chatV3.activeChatIsSub = false;
    chatV3.showingSubAgentHistory = false;
    if (chatV3.masterSessions.isEmpty) {
      await newMasterChatSession();
    } else {
      await openMasterChatSession(chatV3.masterSessions.first);
    }
  }

  void openMasterHistory() {
    chatV3.activeSubAgent = null;
    chatV3.activeChatIsSub = false;
    chatV3.showingSubAgentHistory = false;
    view = AgentView.history;
    pulse();
  }

  Future<void> openMasterChatSession(AgentChatSession session) async {
    chatV3.activeSubAgent = null;
    chatV3.activeChatIsSub = false;
    chatV3.showingSubAgentHistory = false;
    chatV3.sessionId = session.id;
    final saved = await historyApi.messages(session.id);
    messages
      ..clear()
      ..addAll(saved.isEmpty ? [_greeting] : saved);
    view = AgentView.master;
    pulse();
  }

  Future<void> openSubAgentChat(AgentTask task) async {
    await openSubAgentTask(task);
  }

  Future<void> openSubAgentTask(AgentTask task) async {
    if (!AppConfig.showSubAgentUi) return;
    chatV3.activeSubAgent = task;
    chatV3.activeChatIsSub = true;
    chatV3.showingSubAgentHistory = false;
    await loadSubAgentSessions(task);
    final items = chatV3.subSessions[task.id] ?? [];
    if (items.isEmpty) {
      await _createSubAgentSession(task);
    } else {
      await openSubAgentChatSession(task, items.first);
    }
  }

  Future<void> _createSubAgentSession(AgentTask task) async {
    final session = await historyApi.createSession(
      userId: localUserId,
      clientId: localClientId,
      agentType: 'sub',
      modelName: task.agentModelName ?? AppConfig.agentModelName,
      agentId: task.id,
      title: task.agentModelInstance ?? task.title,
    );
    chatV3.activeSubAgent = task;
    chatV3.activeChatIsSub = true;
    chatV3.showingSubAgentHistory = false;
    chatV3.subSessions.putIfAbsent(task.id, () => []).insert(0, session);
    await loadAllSubAgentHistory();
    chatV3.sessionId = session.id;
    view = AgentView.master;
    _resetSubAgentGreeting(task);
    pulse();
  }

  Future<void> openSubAgentChatSession(
    AgentTask task,
    AgentChatSession session,
  ) async {
    chatV3.activeSubAgent = task;
    chatV3.activeChatIsSub = true;
    chatV3.showingSubAgentHistory = false;
    chatV3.sessionId = session.id;
    final saved = await historyApi.messages(session.id);
    messages
      ..clear()
      ..addAll(saved.isEmpty ? [_subAgentGreeting(task)] : saved);
    view = AgentView.master;
    pulse();
  }

  Future<void> openStoredSubAgentSession(AgentChatSession session) async {
    chatV3.activeSubAgent = _taskForSession(session);
    chatV3.activeChatIsSub = true;
    chatV3.showingSubAgentHistory = false;
    chatV3.sessionId = session.id;
    final saved = await historyApi.messages(session.id);
    messages
      ..clear()
      ..addAll(saved.isEmpty
          ? [AgentChatLine('Sub-agent history opened.', false)]
          : saved);
    view = AgentView.master;
    pulse();
  }

  Future<void> loadSubAgentSessions(AgentTask task) async {
    if (!AppConfig.showSubAgentUi) return;
    /*
    chatV3.subSessions[task.id] = await historyApi.listSessions(
      userId: localUserId,
      clientId: localClientId,
      agentType: 'sub',
      agentId: task.id,
    );
    */
  }

  Future<void> loadActiveAgentHistories() async {
    if (!AppConfig.showSubAgentUi) return;
    for (final task in tasks.where((t) => t.hasAgent)) {
      await loadSubAgentSessions(task);
    }
    await loadAllSubAgentHistory();
  }

  Future<void> loadAllSubAgentHistory() async {
    if (!AppConfig.showSubAgentUi) return;
    /*
    final items = await historyApi.listSessions(
      userId: localUserId,
      clientId: localClientId,
      agentType: 'sub',
    );
    final seen = <String>{};
    chatV3.allSubAgentSessions
      ..clear()
      ..addAll(items.where((session) {
        final key = session.agentId ?? session.id;
        return seen.add(key);
      }));
    */
  }

  Future<void> openAllSubAgentHistory() async {
    if (!AppConfig.showSubAgentUi) return;
    chatV3.showingSubAgentHistory = true;
    chatV3.activeChatIsSub = true;
    chatV3.activeSubAgent = null;
    await loadAllSubAgentHistory();
    view = AgentView.history;
    pulse();
  }

  Future<void> deleteChatMessage(int index) async {
    if (loading || index < 0 || index >= messages.length) return;
    final line = messages[index];
    messages.removeAt(index);
    pulse();
    final sessionId = chatV3.sessionId;
    if (sessionId != null && line.id != null) {
      await historyApi.deleteMessage(sessionId, line.id!);
    }
  }

  Future<void> clearChatHistory() async {
    if (loading) return;
    _resetChatGreeting();
    pulse();
    final sessionId = chatV3.sessionId;
    if (sessionId != null) await historyApi.clearMessages(sessionId);
  }

  Future<void> deleteChatSession(AgentChatSession session) async {
    if (loading) return;
    chatV3.masterSessions.removeWhere((s) => s.id == session.id);
    for (final items in chatV3.subSessions.values) {
      items.removeWhere((s) => s.id == session.id);
    }
    chatV3.allSubAgentSessions.removeWhere((s) => s.id == session.id);
    await historyApi.deleteSession(session.id);
    if (chatV3.sessionId == session.id) {
      if (chatV3.sessions.isEmpty) {
        await newChatSession();
      } else {
        await openChatSession(chatV3.sessions.first);
      }
    } else {
      pulse();
    }
  }

  AgentChatLine get _greeting =>
      AgentChatLine('Master agent online. Pick a project or brief me.', false);

  AgentTask? _taskForSession(AgentChatSession session) {
    for (final task in tasks) {
      if (task.id == session.agentId) return task;
    }
    return null;
  }

  Future<List<AgentChatSession>> _listMasterSessions() =>
      historyApi.listSessions(
        userId: localUserId,
        clientId: localClientId,
        agentType: 'master',
      );

  AgentChatLine _subAgentGreeting(AgentTask task) => AgentChatLine(
        'Sub-agent ${task.agentModelInstance ?? task.agent ?? task.title} ready.',
        false,
      );

  void _resetChatGreeting() {
    messages
      ..clear()
      ..add(_greeting);
  }

  void _resetSubAgentGreeting(AgentTask task) {
    messages
      ..clear()
      ..add(_subAgentGreeting(task));
  }
}
