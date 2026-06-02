import 'package:flutter/material.dart';
import '../slavelogic/ai_chat_v2_api.dart';

class ChatMessageV2 {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageData;
  final bool isLoading;

  const ChatMessageV2({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageData,
    this.isLoading = false,
  });

  ChatMessageV2 copyWith({bool? isLoading}) => ChatMessageV2(
        text: text,
        isUser: isUser,
        timestamp: timestamp,
        imageData: imageData,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AiChatV2Mainlogic extends ChangeNotifier {
  final messages = <ChatMessageV2>[];
  final textController = TextEditingController();
  final focusNode = FocusNode();

  bool isLoading = false;
  bool isProcessingFile = false;
  String? selectedImageData;

  AiChatV2Mainlogic() {
    messages.add(ChatMessageV2(
      text: "I'm your AOne UI assistant. Ask me about agents, projects, "
          "tasks, or chat workflows.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    final imageData = selectedImageData;
    if (text.isEmpty && imageData == null) return;

    textController.clear();
    focusNode.requestFocus();

    messages.add(ChatMessageV2(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      imageData: imageData,
      isLoading: true,
    ));
    isLoading = true;
    notifyListeners();

    final result = await AiChatV2Api.generateResponse(
      message: text,
      imageData: imageData,
    );

    _resolveUserMessage();

    if (result['success'] == true) {
      selectedImageData = null;
      messages.add(ChatMessageV2(
        text: result['response'] ?? '',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } else {
      selectedImageData = imageData;
      messages.add(ChatMessageV2(
        text: 'Error: ${result['error']}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    isLoading = false;
    notifyListeners();
  }

  void clearImage() {
    selectedImageData = null;
    isProcessingFile = false;
    notifyListeners();
  }

  void _resolveUserMessage() {
    if (messages.isNotEmpty &&
        messages.last.isUser &&
        messages.last.isLoading) {
      final last = messages.removeLast();
      messages.add(last.copyWith(isLoading: false));
    }
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
