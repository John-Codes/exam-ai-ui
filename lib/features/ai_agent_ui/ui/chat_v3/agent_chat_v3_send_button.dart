import 'package:flutter/material.dart';

class AgentChatV3SendButton extends StatefulWidget {
  final TextEditingController controller;
  final bool busy;
  final bool processing;
  final String? selectedImageData;
  final VoidCallback onSend;

  const AgentChatV3SendButton({
    super.key,
    required this.controller,
    required this.busy,
    required this.processing,
    required this.selectedImageData,
    required this.onSend,
  });

  @override
  State<AgentChatV3SendButton> createState() => _AgentChatV3SendButtonState();
}

class _AgentChatV3SendButtonState extends State<AgentChatV3SendButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(AgentChatV3SendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.busy &&
        !widget.processing &&
        (widget.controller.text.trim().isNotEmpty ||
            widget.selectedImageData != null);
    return IconButton.filled(
      tooltip: widget.busy || widget.processing ? 'Sending' : 'Send',
      onPressed: enabled ? widget.onSend : null,
      icon: Icon(widget.busy || widget.processing
          ? Icons.more_horiz
          : Icons.arrow_upward),
    );
  }
}
