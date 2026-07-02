import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../mainlogic/ai_chat_v2_mainlogic.dart';
import '../mainlogic/thor_voice_controller.dart';
import 'show_voice_error.dart';
import 'voice_record_button.dart';

class VoiceModeButtonV2 extends StatefulWidget {
  const VoiceModeButtonV2(
      {super.key,
      required this.textController,
      required this.onSend,
      required this.messages,
      required this.isLoading});

  final TextEditingController textController;
  final VoidCallback onSend;
  final List<ChatMessageV2> messages;
  final bool isLoading;

  @override
  State<VoiceModeButtonV2> createState() => _VoiceModeButtonV2State();
}

class _VoiceModeButtonV2State extends State<VoiceModeButtonV2> {
  late final ThorVoiceController _voice;

  @override
  void initState() {
    super.initState();
    _voice = ThorVoiceController(
      api: ThorVoiceApi(
          baseUrl: AppConfig.thorVoiceBaseUrl, token: AppConfig.voiceApiToken),
      recorder: VoiceRecorder(),
      player: VoicePlayer(),
      socket: ThorVoiceSocket(),
      socketUrl: AppConfig.thorVoiceWebSocketUrl,
      token: AppConfig.voiceApiToken,
      onTranscript: _showTranscript,
      onSubmit: widget.onSend,
      onError: _showError,
    )..addListener(_refresh);
  }

  void _showTranscript(String text) {
    if (!mounted) return;
    widget.textController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showError(Object error) {
    if (mounted) showVoiceError(context, error);
  }

  @override
  void didUpdateWidget(VoiceModeButtonV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_voice.state != ThorVoiceState.waitingForReply ||
        widget.isLoading ||
        widget.messages.isEmpty) return;
    final message = widget.messages.last;
    if (!message.isUser && !message.isLoading) _voice.speak(message.text);
  }

  Future<void> _toggle() async {
    try {
      if (_voice.state != ThorVoiceState.idle) return await _voice.cancel();
      if (!await _voice.enable() && mounted) {
        _showError(StateError('Microphone permission is required.'));
      }
    } catch (error) {
      await _voice.cancel();
      _showError(error);
    }
  }

  @override
  void dispose() {
    _voice.removeListener(_refresh);
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      VoiceRecordButton(state: _voice.state, onPressed: _toggle);
}
