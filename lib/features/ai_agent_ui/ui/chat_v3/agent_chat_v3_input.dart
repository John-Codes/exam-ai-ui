import 'package:flutter/material.dart';
import 'package:aone_ui/features/ai_chat_v2/mainlogic/ai_chat_v2_mainlogic.dart';
import 'agent_chat_v3_controls.dart';
import 'agent_chat_v3_image.dart';

class AgentChatV3Input extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final bool processing;
  final String? selectedImageData;
  final List<ChatMessageV2> messages;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onClearImage;

  const AgentChatV3Input({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.processing,
    required this.selectedImageData,
    required this.messages,
    required this.onSend,
    required this.onAttach,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width < 640 ? 12.0 : 28.0;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(pad, 10, pad, 12),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                if (selectedImageData != null) ...[
                  AgentChatV3Image(
                    data: selectedImageData!,
                    onClear: onClearImage,
                  ),
                  const SizedBox(height: 8),
                ],
                AgentChatV3Controls(
                  controller: controller,
                  focusNode: focusNode,
                  busy: busy,
                  processing: processing,
                  selectedImageData: selectedImageData,
                  messages: messages,
                  onSend: onSend,
                  onAttach: onAttach,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
