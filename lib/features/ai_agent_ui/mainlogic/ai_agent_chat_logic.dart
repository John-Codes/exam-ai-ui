part of 'ai_agent_mainlogic.dart';

extension AiAgentChatLogic on AiAgentMainlogic {
  Future<void> sendChat() async {
    final text = chatText.text.trim();
    final imageData = chatV3.selectedImageData;
    if (text.isEmpty && imageData == null) return;
    chatText.clear();
    chatV3.focusNode.requestFocus();
    var userLine = AgentChatLine(
      text,
      true,
      imageData: imageData,
      isLoading: true,
    );
    messages.add(userLine);
    loading = true;
    pulse();
    userLine = await _saveMessage(userLine);
    messages[messages.length - 1] = userLine;
    final result = await AgentChatV3Api.generateResponse(
      message: AgentChatV3Prompt.build(messages),
      imageData: imageData,
    );
    _resolveChatLoading();
    if (result['success'] == true) {
      chatV3.selectedImageData = null;
      messages.add(await _saveMessage(
        AgentChatLine(result['response'] ?? '', false),
      ));
    } else {
      chatV3.selectedImageData = imageData;
      messages.add(await _saveMessage(
        AgentChatLine('Error: ${result['error']}', false),
      ));
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

  Future<AgentChatLine> _saveMessage(AgentChatLine line) async {
    final sessionId = chatV3.sessionId;
    if (sessionId == null) return line;
    try {
      return await historyApi.addMessage(
          sessionId, line.copyWith(isLoading: false));
    } catch (_) {
      return line.copyWith(isLoading: false);
    }
  }
}
