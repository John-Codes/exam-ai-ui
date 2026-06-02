import 'package:flutter/material.dart';
import 'package:aone_ui/features/ai_chat_v2/mainlogic/ai_chat_v2_mainlogic.dart';
import 'package:aone_ui/features/ai_chat_v2/slavelogic/ai_chat_v2_image.dart';
import '../../mainlogic/ai_agent_mainlogic.dart';
import 'agent_chat_v3_input.dart';
import 'agent_chat_v3_list.dart';

class AgentChatV3Panel extends StatelessWidget {
  final AiAgentMainlogic logic;
  const AgentChatV3Panel({super.key, required this.logic});

  void _showAttachDialog(BuildContext context) {
    showAttachImageDialog(
      context,
      onGallery: () async {
        logic.setChatImageProcessing(true);
        logic.setChatImage(await pickImageFromGallery());
      },
      onCamera: () async {
        logic.setChatImageProcessing(true);
        logic.setChatImage(await pickImageFromCamera());
      },
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _ChatV3Header(onNewChat: () => logic.newChatSession()),
          Expanded(
            child: AgentChatV3List(
              messages: logic.messages,
              onFeedback: logic.setMessageFeedback,
            ),
          ),
          if (logic.loading) const LinearProgressIndicator(minHeight: 2),
          AgentChatV3Input(
            controller: logic.chatText,
            focusNode: logic.chatV3.focusNode,
            busy: logic.loading,
            processing: logic.chatV3.isProcessingFile,
            selectedImageData: logic.chatV3.selectedImageData,
            messages: _voiceMessages,
            onSend: logic.sendChat,
            onAttach: () => _showAttachDialog(context),
            onClearImage: logic.clearChatImage,
          ),
        ],
      );

  List<ChatMessageV2> get _voiceMessages => [
        for (final m in logic.messages)
          ChatMessageV2(
            text: m.text,
            isUser: m.mine,
            timestamp: m.timestamp,
            imageData: m.imageData,
            isLoading: m.isLoading,
          ),
      ];
}

class _ChatV3Header extends StatelessWidget {
  final VoidCallback onNewChat;
  const _ChatV3Header({required this.onNewChat});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chat v3',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: onNewChat,
            ),
          ],
        ),
      );
}
