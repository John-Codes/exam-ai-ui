import 'package:flutter/material.dart';

import '../../ai_agent_ui/ui/chat_v3/agent_chat_v3_list.dart';
import '../../ai_chat_v2/mainlogic/ai_chat_v2_mainlogic.dart';
import '../../ai_chat_v2/voice/ui/voice_mode_button.dart';
import '../quiz/quiz_controller.dart';
import '../quiz/quiz_models.dart';

/// AI quiz mode. Boots straight into a chat with a "letter-answer or ask"
/// loop over the published CDL question bank, with voice TTS/STT and the
/// exam-api LLM proxy for free-text follow-ups.
class AiQuizScreen extends StatefulWidget {
  const AiQuizScreen({super.key});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen> {
  final QuizSession _session = QuizSession();
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  QuizSubject? _picked;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
    final slug = Uri.base.queryParameters['subject'];
    final preselect = quizSubjectForSlug(slug);
    if (preselect != null) {
      _picked = preselect;
      WidgetsBinding.instance.addPostFrameCallback((_) => _session.start(preselect));
    }
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _session.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<ChatMessageV2> get _voiceMessages => [
        for (final m in _session.messages)
          ChatMessageV2(
            text: m.text,
            isUser: m.mine,
            timestamp: m.timestamp,
            isLoading: m.isLoading,
          ),
      ];

  void _send() {
    if (_session.aiBusy || _session.starting) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _session.send(text);
    _input.clear();
    _focus.requestFocus();
  }

  void _goHome() {
    setState(() => _picked = null);
  }

  @override
  Widget build(BuildContext context) {
    final subject = _picked;
    if (subject == null) {
      return _SubjectPicker(onPick: (s) {
        setState(() => _picked = s);
        _session.start(s);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              children: [
                const _AdBanner(),
                _QuizHeader(
                  session: _session,
                  subject: subject,
                  onRestart: () => _session.restart(),
                  onHome: _goHome,
                ),
                Expanded(child: _buildBody()),
                if (_session.aiBusy) const LinearProgressIndicator(minHeight: 2),
                _InputBar(
                  controller: _input,
                  focusNode: _focus,
                  enabled: _session.inProgress,
                  busy: _session.aiBusy || _session.starting,
                  messages: _voiceMessages,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_session.starting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_session.error != null && _session.messages.isEmpty) {
      return _ErrorView(
        message: _session.error!,
        onRetry: _session.restart,
        onHome: _goHome,
      );
    }
    return AgentChatV3List(
      messages: _session.messages,
      onFeedback: (_, __) {},
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text('Advertisement',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  )),
        ],
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({
    required this.session,
    required this.subject,
    required this.onRestart,
    required this.onHome,
  });

  final QuizSession session;
  final QuizSubject subject;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = session.total;
    final livePct = session.answered > 0
        ? (session.correctCount * 100 / session.answered).round()
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Change subject',
                icon: const Icon(Icons.home_outlined),
                onPressed: onHome,
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B3CFF), Color(0xFF4F8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text('AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.done ? 'Results · ${subject.title}' : 'AI Quiz · ${subject.title}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (total > 0)
                      Text(
                        '${session.done ? total : session.index + 1} of $total questions · pass = 80%',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'New quiz',
                icon: const Icon(Icons.refresh),
                onPressed: onRestart,
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(context, '${session.correctCount} ✓', scheme.primary),
                _chip(context, '${session.wrongCount} ✗', scheme.error),
                if (livePct != null)
                  _chip(context, '$livePct%', Colors.amber.shade700),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.busy,
    required this.messages,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool busy;
  final List<ChatMessageV2> messages;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pad = MediaQuery.sizeOf(context).width < 640 ? 12.0 : 28.0;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(pad, 10, pad, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Your answer (A, B, C, D) or a question…'
                      : 'Session finished — start a new quiz',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 2),
              child: VoiceModeButtonV2(
                textController: controller,
                onSend: onSend,
                messages: messages,
                isLoading: busy,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 2),
              child: IconButton.filled(
                tooltip: 'Send',
                onPressed: enabled ? onSend : null,
                icon: const Icon(Icons.arrow_upward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onHome,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                SelectableText(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(onPressed: onHome, child: const Text('Pick a subject')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: onRetry, child: const Text('Try again')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectPicker extends StatelessWidget {
  const _SubjectPicker({required this.onPick});

  final ValueChanged<QuizSubject> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B3CFF), Color(0xFF4F8CFF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('AI Quiz Mode',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text('Pick a subject',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Same official question bank, but you chat with an AI tutor. '
                  'Reply with the letter A–D, ask questions anytime, and use '
                  'voice mode to talk it through.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                for (final s in kQuizSubjects) ...[
                  _SubjectCard(subject: s, onTap: () => onPick(s)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});

  final QuizSubject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B3CFF), Color(0xFF4F8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(subject.abbr,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subject.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome,
                  size: 18, color: Color(0xFF7B3CFF)),
            ],
          ),
        ),
      ),
    );
  }
}