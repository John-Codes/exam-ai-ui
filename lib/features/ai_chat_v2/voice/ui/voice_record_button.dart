import 'package:flutter/material.dart';

import '../mainlogic/thor_voice_controller.dart';

class VoiceRecordButton extends StatelessWidget {
  const VoiceRecordButton(
      {super.key, required this.state, required this.onPressed});

  final ThorVoiceState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final listening = state == ThorVoiceState.listening;
    final active = state != ThorVoiceState.idle;
    final icon = switch (state) {
      ThorVoiceState.speaking => Icons.volume_up,
      ThorVoiceState.waitingForReply => Icons.hourglass_top,
      ThorVoiceState.connecting => Icons.sync,
      ThorVoiceState.listening => Icons.mic,
      ThorVoiceState.idle => Icons.mic_none,
    };
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: active ? 'Cancel voice mode' : 'Start Thor voice mode',
      style: IconButton.styleFrom(
        backgroundColor: listening ? Colors.red[600] : Colors.grey[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}
