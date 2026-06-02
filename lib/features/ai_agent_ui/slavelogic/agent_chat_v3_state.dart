import 'package:flutter/material.dart';
import 'agent_models.dart';

class AgentChatV3State {
  final focusNode = FocusNode();
  final masterSessions = <AgentChatSession>[];
  final subSessions = <String, List<AgentChatSession>>{};
  final allSubAgentSessions = <AgentChatSession>[];
  String? masterSessionId;
  String? subSessionId;
  AgentTask? activeSubAgent;
  bool activeChatIsSub = false;
  bool showingSubAgentHistory = false;
  String? selectedImageData;
  bool isProcessingFile = false;
  bool historyLoading = false;

  List<AgentChatSession> get sessions {
    if (showingSubAgentHistory) return allSubAgentSessions;
    return activeChatIsSub ? activeSubSessions : masterSessions;
  }

  List<AgentChatSession> get activeSubSessions =>
      subSessions[activeSubAgent?.id] ?? const [];

  String? get sessionId => activeChatIsSub ? subSessionId : masterSessionId;

  set sessionId(String? value) {
    if (activeChatIsSub) {
      subSessionId = value;
    } else {
      masterSessionId = value;
    }
  }

  void dispose() => focusNode.dispose();
}
