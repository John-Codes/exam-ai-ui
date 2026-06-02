import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../mainlogic/ai_chat_v2_mainlogic.dart';

class VoiceModeButtonV2 extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onSend;
  final List<ChatMessageV2> messages;
  final bool isLoading;

  const VoiceModeButtonV2({
    super.key,
    required this.textController,
    required this.onSend,
    required this.messages,
    required this.isLoading,
  });

  @override
  State<VoiceModeButtonV2> createState() => _VoiceModeButtonV2State();
}

class _VoiceModeButtonV2State extends State<VoiceModeButtonV2>
    with SingleTickerProviderStateMixin {
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();

  bool _voiceMode = false;
  bool _listening = false;
  bool _speaking = false;
  bool _sttAvailable = false;
  String? _lastSpokenKey;

  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _initTts();
    _initStt();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.52);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    void onDone() {
      if (!mounted) return;
      setState(() => _speaking = false);
      _maybeRestartListening();
    }

    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(onDone);
    _tts.setCancelHandler(onDone);
    _tts.setErrorHandler((_) => onDone());
  }

  Future<void> _initStt() async {
    final available = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() => _listening = false);
        Future.delayed(
          const Duration(milliseconds: 800),
          _maybeRestartListening,
        );
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
          Future.delayed(
            const Duration(milliseconds: 400),
            _maybeRestartListening,
          );
        }
      },
    );
    if (mounted) setState(() => _sttAvailable = available);
  }

  void _maybeRestartListening() {
    if (!mounted ||
        !_voiceMode ||
        widget.isLoading ||
        _speaking ||
        _listening) {
      return;
    }
    _startListening();
  }

  @override
  void didUpdateWidget(VoiceModeButtonV2 old) {
    super.didUpdateWidget(old);
    if (!_voiceMode) return;

    if (widget.messages.isNotEmpty) {
      final last = widget.messages.last;
      if (!last.isUser && !last.isLoading && last.text.isNotEmpty) {
        final key = last.timestamp.millisecondsSinceEpoch.toString();
        if (key != _lastSpokenKey) {
          _lastSpokenKey = key;
          _speak(last.text);
          return;
        }
      }
    }

    if (!widget.isLoading && old.isLoading) {
      Future.delayed(
        const Duration(milliseconds: 350),
        _maybeRestartListening,
      );
    }
  }

  Future<void> _speak(String text) async {
    if (_listening) await _stopListening();
    setState(() => _speaking = true);
    final cleaned = text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'`[^`]*`'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .trim();
    await _tts.speak(cleaned);
  }

  Future<void> _startListening() async {
    if (!_sttAvailable || _listening) return;
    if (mounted) setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.isNotEmpty) {
          widget.textController.text = words;
          widget.textController.selection =
              TextSelection.fromPosition(TextPosition(offset: words.length));
        }
        if (result.finalResult && words.isNotEmpty) {
          if (mounted) setState(() => _listening = false);
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _voiceMode) widget.onSend();
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _toggleVoiceMode() async {
    if (_voiceMode) {
      await _stopListening();
      await _tts.stop();
      if (mounted) {
        setState(() {
          _voiceMode = false;
          _speaking = false;
          _lastSpokenKey = null;
        });
      }
    } else {
      if (!_sttAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone not available on this device.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (mounted) setState(() => _voiceMode = true);
      await _startListening();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final IconData icon;
    final String tip;

    if (!_voiceMode) {
      bg = Colors.grey[700]!;
      icon = Icons.mic_none;
      tip = 'Enable voice mode';
    } else if (_listening) {
      bg = Colors.red[600]!;
      icon = Icons.mic;
      tip = 'Listening… tap to exit';
    } else if (_speaking) {
      bg = Colors.teal[600]!;
      icon = Icons.volume_up;
      tip = 'Speaking… tap to exit';
    } else {
      bg = Colors.deepPurple[500]!;
      icon = Icons.mic;
      tip = 'Voice on — tap to exit';
    }

    Widget btn = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _voiceMode
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: _toggleVoiceMode,
        tooltip: tip,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(12),
          hoverColor: Colors.deepPurple[400],
        ),
      ),
    );

    if (_listening) btn = ScaleTransition(scale: _pulseAnim, child: btn);
    return btn;
  }
}
