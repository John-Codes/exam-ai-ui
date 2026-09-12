import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../features/ai_agent_ui/slavelogic/agent_models.dart';
import '../../../features/ai_agent_ui/slavelogic/models/agent_chat_line.dart';
import 'quiz_api.dart';
import 'quiz_models.dart';

/// Deterministic, chat-based AI quiz session.
///
/// Same published question bank as the classic text quiz, in random order.
/// The learner replies with the option letter (A-D), scored locally against
/// the bank's answer key; free-text questions go to the LLM proxy on the
/// exam API. Pass = 80%+.
class QuizSession extends ChangeNotifier {
  QuizSession({AiQuizApi? api}) : api = api ?? AiQuizApi();

  final AiQuizApi api;
  final Random _rng = Random();

  QuizSubject? subject;
  final messages = <AgentChatLine>[];
  List<QuizQuestion> pool = [];

  int index = 0;
  int correctCount = 0;
  int wrongCount = 0;

  bool starting = false;
  bool aiBusy = false;
  bool choosingSubject = false;
  String? error;
  DateTime? startedAt;

  int get total => pool.length;
  int get answered => correctCount + wrongCount;
  bool get done => total > 0 && index >= total;
  bool get inProgress => total > 0 && !done && error == null;
  bool get canInteract => choosingSubject || inProgress;

  int? get scorePercent {
    if (total == 0) return null;
    return (correctCount * 100 / total).round();
  }

  bool? get passed {
    final pct = scorePercent;
    if (pct == null) return null;
    return pct >= 80;
  }

  /// Opens the conversational "which test?" phase: a greeting from the AI
  /// tutor, answering in any language. Tap a chip or type/say a subject.
  void beginSubjectSelection() {
    choosingSubject = true;
    subject = null;
    pool = [];
    index = 0;
    correctCount = 0;
    wrongCount = 0;
    startedAt = null;
    error = null;
    aiBusy = false;
    starting = false;
    messages.clear();
    _push(AgentChatLine(_subjectPromptMarkdown(), false));
    notifyListeners();
  }

  Future<void> chooseSubject(String raw) async {
    if (!choosingSubject || raw.trim().isEmpty) return;
    final text = raw.trim();
    _push(AgentChatLine(text, true));
    notifyListeners();

    final local = quizSubjectForText(text);
    if (local != null) {
      await start(local);
      return;
    }
    aiBusy = true;
    notifyListeners();
    try {
      final slug = await api.resolveSubject(text);
      final subject = quizSubjectForSlug(slug);
      if (subject != null) {
        await start(subject);
        return;
      }
      _push(AgentChatLine(_subjectRetryMarkdown(), false));
    } catch (e) {
      _push(AgentChatLine(
        '⚠️ I had trouble reaching the AI tutor:\n\n`$e`\n\n'
        'You can also tap a subject below.',
        false,
      ));
    } finally {
      aiBusy = false;
      notifyListeners();
    }
  }

  Future<void> start(QuizSubject subject) async {
    this.subject = subject;
    choosingSubject = false;
    starting = true;
    error = null;
    index = 0;
    correctCount = 0;
    wrongCount = 0;
    startedAt = DateTime.now();
    messages.clear();
    notifyListeners();
    try {
      final questions = await api.fetchQuestions(subject: subject.slug);
      if (questions.isEmpty) {
        error = 'No questions are published for ${subject.title} yet. '
            'Check back soon or try another subject.';
      } else {
        pool = [...questions]..shuffle(_rng);
        _push(AgentChatLine(_questionMarkdown(0), false));
      }
    } catch (e) {
      error = 'Could not load the question bank.\n\n`$e`';
    } finally {
      starting = false;
      notifyListeners();
    }
  }

  Future<void> restart() async {
    if (subject != null) await start(subject!);
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || done || subject == null) return;
    _push(AgentChatLine(text, true));
    notifyListeners();

    final q = pool[index];
    final letter = _parseAnswer(text);
    if (letter != null) {
      await _grade(q, letter);
    } else {
      await _askAi(q, text);
    }
    notifyListeners();
  }

  Future<void> _grade(QuizQuestion q, String letter) async {
    final correct = q.answerKey.contains(letter);
    if (correct) {
      correctCount++;
    } else {
      wrongCount++;
    }
    _push(AgentChatLine(_feedbackMarkdown(q, letter, correct), false));
    index++;
    if (done) {
      _push(AgentChatLine(_resultsMarkdown(), false));
      notifyListeners();
      await _recordAttempt();
    } else {
      _push(AgentChatLine(_questionMarkdown(index), false));
    }
  }

  Future<void> _askAi(QuizQuestion q, String userText) async {
    aiBusy = true;
    notifyListeners();
    try {
      final history = messages
          .map((m) => {
                'role': m.mine ? 'user' : 'assistant',
                'text': m.text,
              })
          .toList();
      final reply = await api.aiExplain(
        question: q,
        userText: userText,
        history: history.length > 10 ? history.sublist(history.length - 10) : history,
      );
      _push(AgentChatLine(reply.isEmpty ? '(no reply)' : reply, false));
    } catch (e) {
      _push(AgentChatLine(
        '⚠️ I had trouble reaching the AI tutor:\n\n`$e`\n\n'
        'Reply **A, B, C or D** to continue, or try your question again.',
        false,
      ));
    } finally {
      aiBusy = false;
    }
  }

  Future<void> _recordAttempt() async {
    await api.recordAttempt(
      tag: 'ai-${subject?.slug ?? 'unknown'}',
      total: total,
      correct: correctCount,
      passed: passed == true,
      durationS: startedAt == null
          ? null
          : DateTime.now().difference(startedAt!).inSeconds,
    );
  }

  // ── message builders ────────────────────────────────────────────────────

  String _subjectPromptMarkdown() {
    return 'Welcome! I\'m your CDL exam tutor. 🚚📚\n\n'
        '**Which test would you like to take?**\n\n'
        'You can tell me in your own language — for example:\n'
        '- "air brakes"\n'
        '- "prueba de frenos de aire"\n'
        '- "hazmat"\n\n'
        'Reply here, use the microphone 🎤, or tap a subject below.';
  }

  String _subjectRetryMarkdown() {
    return 'Hmm, I didn\'t catch which test you meant. Try one of these, or tap a '
        'subject below:\n\n'
        '**General Knowledge** · **Air Brakes** · **Combination Vehicles** · '
        '**Tanker** · **Hazmat** · **Passenger Bus** · **School Bus**';
  }

  String _questionMarkdown(int i) {
    final q = pool[i];
    final buf = StringBuffer()
      ..writeln('**Question ${i + 1} of $total · ${subject?.title}**')
      ..writeln()
      ..writeln(q.stem)
      ..writeln();
    for (final c in q.choices) {
      buf.writeln('**${c.key}.** ${c.text}');
    }
    buf
      ..writeln()
      ..writeln('Reply with the **letter** (A, B, C or D) — or ask me to explain it.');
    return buf.toString();
  }

  String _feedbackMarkdown(QuizQuestion q, String letter, bool correct) {
    final correctLetter = q.answerKey.isNotEmpty ? q.answerKey.first : letter;
    final correctText = q.choiceText(correctLetter) ?? '';
    var explanation = q.explanation?.trim();
    if (explanation == null || explanation.isEmpty) {
      explanation = q.explanationForChoice(correctLetter);
    }

    var out = correct
        ? '✅ **Correct!** (${letter.toUpperCase()})\n\n'
        : '❌ **Not quite.** The correct answer is '
            '**$correctLetter — $correctText**.\n\n';
    if (explanation != null) out += '$explanation\n\n';
    out += '_Score: $correctCount right · $wrongCount wrong · '
        '${answered}/$total answered._';
    return out.trim();
  }

  String _resultsMarkdown() {
    final pct = scorePercent ?? 0;
    final headline = pct >= 80
        ? '🎉 **PASSED** — $pct%'
        : '📚 **KEEP PRACTICING** — $pct%';
    return '**AI Quiz complete — ${subject?.title}**\n\n'
        '$headline\n\n'
        '✅ Correct: $correctCount\n'
        '❌ Wrong: $wrongCount\n'
        '📝 Answered: $answered/$total\n\n'
        'The passing score is **80%**. Tap **New quiz** to try again, '
        'or pick another subject.';
  }

  void _push(AgentChatLine line) {
    messages.add(line);
  }
}

/// Recognizes a letter-based answer (handles voice-transcription spelling and
/// phrases like "option b" or "the answer is d"). Returns normalized A-D or
/// null when the message is free text.
String? _parseAnswer(String text) {
  var t = text.trim().toLowerCase();
  if (t.isEmpty) return null;
  const map = <String, String>{
    'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D',
    'ay': 'A', 'aye': 'A',
    'bee': 'B', 'be': 'B',
    'see': 'C', 'sea': 'C',
    'dee': 'D', 'de': 'D',
  };
  for (final prefix in const ['option ', 'the letter ', 'the answer is ']) {
    if (t.startsWith(prefix) && t.length > prefix.length) {
      t = t.substring(prefix.length).trim();
      break;
    }
  }
  t = t.replaceAll(RegExp(r'[.,!?\s]+$'), '');
  t = t.replaceAll(RegExp(r'^[\s.]+'), '');
  return map[t];
}