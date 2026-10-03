import 'package:flutter/material.dart';

import '../../ai_agent_ui/ui/chat_v3/agent_chat_v3_list.dart';
import '../../ai_chat_v2/mainlogic/ai_chat_v2_mainlogic.dart';
import '../../ai_chat_v2/voice/ui/voice_mode_button.dart';
import '../quiz/openrouter_key_store.dart';
import '../quiz/quiz_api.dart';
import '../quiz/quiz_controller.dart';
import '../quiz/quiz_models.dart';
import 'fun_loading_view.dart';

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

  /// Collapsible "how to use AI mode" panel.
  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _AiHelpPanel(),
    );
  }

  /// Settings dialog: connect the user's own (optional, free) OpenRouter key.
  Future<void> _showSettings() async {
    final initial = await OpenRouterKeyStore.has();
    if (!mounted) return;
    final controller = TextEditingController();
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _ByokDialog(
        controller: controller,
        hasKey: initial,
        api: _session.api,
      ),
    );
    controller.dispose();
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your AI settings were saved.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                  onHelp: _showHelp,
                  onSettings: _showSettings,
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
                  quietHint: choosing
                      ? 'Conversation mode works in any language — no need to write full sentences.'
                      : 'Tip: voice & conversation mode work best in a quiet spot.',
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
      return FunLoadingView(
        hint: _picked != null
            ? 'Loading ${_picked!.title} questions…'
            : 'Loading your questions…',
      );
    }
    if (_session.error != null && _session.messages.isEmpty) {
      return _ErrorView(
        message: _session.error!,
        onRetry: _session.restart,
        onHome: _goHome,
      );
    }
    if (_session.messages.isEmpty) {
      // Defensive: never render a totally blank canvas between states.
      return const FunLoadingView();
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
    required this.onHelp,
    required this.onSettings,
  });

  final QuizSession session;
  final QuizSubject? subject;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onHelp;
  final VoidCallback onSettings;

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
              IconButton(
                tooltip: 'How to use AI mode',
                icon: const Icon(Icons.help_outline),
                onPressed: onHelp,
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: onSettings,
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
    required this.quietHint,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool busy;
  final List<ChatMessageV2> messages;
  final String hintText;
  final String quietHint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pad = MediaQuery.sizeOf(context).width < 640 ? 12.0 : 28.0;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(pad, 8, pad, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      size: 13, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      quietHint,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Row(
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
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet "how to use AI mode" guidance shown from the header help icon.
class _AiHelpPanel extends StatelessWidget {
  const _AiHelpPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.bodyMedium;
    final style = TextStyle(color: scheme.onSurfaceVariant, height: 1.45);
    Widget bullet(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: text?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(body, style: style),
                  ],
                ),
              ),
            ],
          ),
        );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'How to use AI mode',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            bullet(Icons.record_voice_over_outlined, 'Chat in your own words',
                'Type or talk in any language. Build confidence by summarizing '
                    'what you know — you don\'t need full sentences.'),
            bullet(Icons.volume_off_outlined, 'Use it in a quiet spot',
                'Voice and conversation mode work best somewhere quiet — '
                    'background noise confuses speech recognition.'),
            bullet(Icons.swap_horiz_outlined, 'Answers & skipping',
                'Reply with the letter (A, B, C or D) to answer. Stuck on a '
                    'question? Type **skip** to move past it — question order '
                    'isn\'t the point.'),
            bullet(Icons.settings_outlined, 'Your own AI key (optional)',
                'If the free tutor is busy, tap ⚙ Settings to connect your own '
                    'free OpenRouter key. It stays only in this browser.'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Dialog for connecting (or removing) the user's own OpenRouter key.
class _ByokDialog extends StatefulWidget {
  const _ByokDialog({
    required this.controller,
    required this.hasKey,
    required this.api,
  });

  final TextEditingController controller;
  final bool hasKey;
  final AiQuizApi api;

  @override
  State<_ByokDialog> createState() => _ByokDialogState();
}

class _ByokDialogState extends State<_ByokDialog> {
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    await OpenRouterKeyStore.set(widget.controller.text);
    await widget.api.refreshOpenRouterKey();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _clear() async {
    setState(() => _busy = true);
    await OpenRouterKeyStore.clear();
    await widget.api.refreshOpenRouterKey();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('AI settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hasKey
                  ? 'Your own AI key is connected. Paste a new one to change it, '
                      'or remove it below.'
                  : 'Connect your own (free) OpenRouter AI key to unlock AI '
                      'tutoring even when the built-in tutor is busy.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.controller,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'OpenRouter API key (optional)',
                hintText: 'sk-or-…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stored only in this browser and never shown in chat.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.hasKey)
          TextButton(
            onPressed: _busy ? null : _clear,
            child: const Text('Remove key'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save'),
        ),
      ],
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