import 'package:flutter/material.dart';

import '../../ai_agent_ui/ui/chat_v3/agent_chat_v3_list.dart';
import '../../ai_chat_v2/mainlogic/ai_chat_v2_mainlogic.dart';
import '../../ai_chat_v2/voice/ui/voice_mode_button.dart';
import '../quiz/quiz_controller.dart';
import '../quiz/quiz_models.dart';

/// AI quiz mode. Boots straight into a conversational "which test?" phase —
/// the AI tutor asks what to take and understands any language — then runs the
/// letter-answer / free-text loop over the published CDL question bank, with
/// voice TTS/STT and the exam-api LLM proxy for follow-ups.
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
    } else {
      _session.beginSubjectSelection();
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
    if (_picked == null) {
      _session.chooseSubject(text);
    } else {
      _session.send(text);
    }
    _input.clear();
    _focus.requestFocus();
  }

  void _pick(QuizSubject subject) {
    setState(() => _picked = subject);
    _session.start(subject);
  }

  void _goHome() {
    setState(() => _picked = null);
    _session.beginSubjectSelection();
  }

  @override
  Widget build(BuildContext context) {
    final subject = _picked;
    final choosing = subject == null;

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
                if (choosing) _SubjectChips(onPick: _pick),
                Expanded(child: _buildBody()),
                if (_session.aiBusy) const LinearProgressIndicator(minHeight: 2),
                _InputBar(
                  controller: _input,
                  focusNode: _focus,
                  enabled: _session.canInteract,
                  busy: _session.aiBusy || _session.starting,
                  messages: _voiceMessages,
                  hintText: choosing
                      ? 'Which test would you like to take?'
                      : 'Your answer (A, B, C, D) or a question…',
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
  final QuizSubject? subject;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = session.total;
    final livePct = session.answered > 0
        ? (session.correctCount * 100 / session.answered).round()
        : null;
    final title = subject == null
        ? 'AI Quiz · Pick a subject'
        : (session.done ? 'Results · ${subject!.title}' : 'AI Quiz · ${subject!.title}');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Start over (pick a subject)',
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
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (total > 0 && subject != null)
                      Text(
                        '${session.done ? total : session.index + 1} of $total questions · pass = 80%',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      )
                    else
                      Text(
                        'Works in any language',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (subject != null)
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

/// Quick-pick chips shown during the "which test?" phase.
class _SubjectChips extends StatelessWidget {
  const _SubjectChips({required this.onPick});

  final ValueChanged<QuizSubject> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in kQuizSubjects)
            ActionChip(
              avatar: Icon(Icons.auto_awesome,
                  size: 15, color: scheme.secondary),
              label: Text(s.title),
              visualDensity: VisualDensity.compact,
              onPressed: () => onPick(s),
            ),
        ],
      ),
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
    required this.hintText,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool busy;
  final List<ChatMessageV2> messages;
  final String hintText;
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
                      ? hintText
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