import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aone_ui/features/ai_chat_v2/mainlogic/ai_chat_v2_mainlogic.dart';
import 'package:aone_ui/features/ai_chat_v2/slavelogic/ai_chat_v2_voice.dart';
import 'agent_chat_v3_send_button.dart';

class AgentChatV3Controls extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final bool processing;
  final String? selectedImageData;
  final List<ChatMessageV2> messages;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const AgentChatV3Controls({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.processing,
    required this.selectedImageData,
    required this.messages,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) => Focus(
        onKeyEvent: (_, event) {
          final enter = event.logicalKey == LogicalKeyboardKey.enter;
          final shift = HardwareKeyboard.instance.isShiftPressed;
          final canSend = !busy &&
              !processing &&
              (controller.text.trim().isNotEmpty || selectedImageData != null);
          if (canSend && enter && !shift && event is KeyDownEvent) {
            onSend();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 2),
              child: IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: onAttach,
              ),
            ),
            Expanded(
                child: _ChatField(controller: controller, node: focusNode)),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: VoiceModeButtonV2(
                textController: controller,
                onSend: onSend,
                messages: messages,
                isLoading: busy,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: AgentChatV3SendButton(
                controller: controller,
                busy: busy,
                processing: processing,
                selectedImageData: selectedImageData,
                onSend: onSend,
              ),
            ),
          ],
        ),
      );
}

class _ChatField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode node;
  const _ChatField({required this.controller, required this.node});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: node,
        minLines: 1,
        maxLines: 6,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: 'Message chat v3',
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      );
}
