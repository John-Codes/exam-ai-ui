part of 'ai_agent_mainlogic.dart';

extension AiAgentChatLogic on AiAgentMainlogic {
  Future<void> sendChat() async {
    final text = chatText.text.trim();
    final imageData = chatV3.selectedImageData;
    if (text.isEmpty && imageData == null) return;
    chatText.clear();
    chatV3.focusNode.requestFocus();
    final userLine = AgentChatLine(
      text,
      true,
      imageData: imageData,
      isLoading: false,
    );
    messages.add(userLine);
    loading = true;
    pulse();
    final result = await AgentChatV3Api.generateResponse(
      message: AgentChatV3Prompt.build(messages),
      userMessage: text,
      sessionId: chatV3.sessionId ?? '',
      imageData: imageData,
    );
    _resolveChatLoading();
    if (result['success'] == true) {
      chatV3.selectedImageData = null;
      messages.add(AgentChatLine(result['response'] ?? '', false));
      await _reloadPersistedChatMessages();
    } else {
      chatV3.selectedImageData = imageData;
      messages.add(AgentChatLine('Error: ${result['error']}', false));
    }
    loading = false;
    await refreshChatSessions();
    pulse();
  }

  void clearChatImage() {
    chatV3.selectedImageData = null;
    chatV3.isProcessingFile = false;
    pulse();
  }

  void setChatImage(String? data) {
    chatV3.selectedImageData = data;
    chatV3.isProcessingFile = false;
    pulse();
  }

  void setChatImageProcessing(bool value) {
    chatV3.isProcessingFile = value;
    pulse();
  }

  void _resolveChatLoading() {
    if (messages.isEmpty || !messages.last.mine || !messages.last.isLoading) {
      return;
    }
    final last = messages.removeLast();
    messages.add(last.copyWith(isLoading: false));
  }

  Future<void> _reloadPersistedChatMessages() async {
    final sessionId = chatV3.sessionId;
    if (sessionId == null) return;
    try {
      final saved = await historyApi.messages(sessionId);
      messages
        ..clear()
        ..addAll(saved);
    } catch (_) {}
  }
}
