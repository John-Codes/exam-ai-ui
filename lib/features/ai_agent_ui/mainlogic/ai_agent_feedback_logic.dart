part of 'ai_agent_mainlogic.dart';

extension AiAgentFeedbackLogic on AiAgentMainlogic {
  Future<void> setMessageFeedback(AgentChatLine line, String value) async {
    final sessionId = chatV3.sessionId;
    if (loading || sessionId == null || line.id == null || line.mine) return;
    final next = line.feedback == value ? null : value;
    final index = messages.indexWhere((m) => m.id == line.id);
    if (index < 0) return;
    messages[index] = line.copyWith(feedback: next);
    pulse();
    final saved = await historyApi.setFeedback(
      sessionId: sessionId,
      messageId: line.id!,
      feedback: next,
    );
    final savedIndex = messages.indexWhere((m) => m.id == saved.id);
    if (savedIndex >= 0) messages[savedIndex] = saved;
    pulse();
  }
}
