import 'package:aone_ui/features/ai_quiz/quiz/quiz_api.dart';
import 'package:aone_ui/features/ai_quiz/quiz/quiz_controller.dart';
import 'package:aone_ui/features/ai_quiz/quiz/quiz_models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApi extends AiQuizApi {
  FakeApi() : super(base: 'http://unused', workspace: 'ws_1');

  int aiCalls = 0;
  int attemptCalls = 0;
  int resolveCalls = 0;
  String? resolveResult = 'air-brakes';

  bool get resolvedWithoutLlm => resolveCalls == 0;

  @override
  Future<List<QuizQuestion>> fetchQuestions({
    required String subject,
    int limit = 50,
  }) async {
    return [
      QuizQuestion(
        id: 'q1',
        stem: 'Question one?',
        choices: const [
          QuizChoice(key: 'A', text: 'one'),
          QuizChoice(key: 'B', text: 'two'),
          QuizChoice(key: 'C', text: 'three'),
          QuizChoice(key: 'D', text: 'four'),
        ],
        answerKey: const ['B'],
        explanation: 'Because B.',
      ),
      QuizQuestion(
        id: 'q2',
        stem: 'Question two?',
        choices: const [
          QuizChoice(key: 'A', text: 'alpha'),
          QuizChoice(key: 'B', text: 'beta'),
          QuizChoice(key: 'C', text: 'gamma'),
          QuizChoice(key: 'D', text: 'delta'),
        ],
        answerKey: const ['D'],
      ),
    ];
  }

  @override
  Future<String> aiExplain({
    required QuizQuestion question,
    required String userText,
    required List<Map<String, String>> history,
    bool revealCorrect = false,
  }) async {
    aiCalls++;
    return 'Tutor hint';
  }

  @override
  Future<void> recordAttempt({
    required String tag,
    required int total,
    required int correct,
    required bool passed,
    int? durationS,
  }) async {
    attemptCalls++;
  }

  @override
  Future<String?> resolveSubject(String text) async {
    resolveCalls++;
    return resolveResult;
  }
}

const _letterSpell = <String, String>{'A': 'ay', 'B': 'bee', 'C': 'see', 'D': 'dee'};

String quiz_models_spell(String letter) =>
    _letterSpell[letter.toUpperCase()] ?? letter.toLowerCase();

void main() {
  test('letter answers are scored deterministically and free text hits LLM',
      () async {
    final api = FakeApi();
    final session = QuizSession(api: api);
    await session.start(kQuizSubjects.first);

    expect(session.total, 2);
    expect(session.done, false);

    // Send a wrong letter for whichever question is first (order-agnostic).
    final first = session.pool.first;
    final wrongLetter = ['A', 'B', 'C', 'D']
        .firstWhere((l) => !first.answerKey.contains(l));
    await session.send(wrongLetter);
    expect(session.wrongCount, 1);
    expect(session.correctCount, 0);
    expect(session.done, false);

    // Voice-style answer for the remaining question's correct letter.
    final remaining = session.pool.last;
    await session.send(quiz_models_spell(remaining.answerKey.first));
    expect(session.correctCount, 1);
    expect(session.done, true);
    expect(session.scorePercent, 50);
    expect(session.passed, false);
    expect(api.attemptCalls, 1);

    final text = session.messages.map((m) => m.text).join('\n');
    expect(text, contains('KEEP PRACTICING'));
    expect(text, contains('50%'));
  });

  test('free text goes to the AI tutor and appends a reply', () async {
    final api = FakeApi();
    final session = QuizSession(api: api);
    await session.start(kQuizSubjects.first);

    await session.send('can you explain this?');
    expect(api.aiCalls, 1);
    final last = session.messages.last;
    expect(last.mine, false);
    expect(last.text, 'Tutor hint');
    // Question still pending.
    expect(session.done, false);
    expect(session.answered, 0);
  });

  test('phrase answers parse', () async {
    final api = FakeApi();
    final session = QuizSession(api: api);
    await session.start(kQuizSubjects.first);
    final correct = session.pool.first.answerKey.first.toLowerCase();
    await session.send('the answer is $correct');
    expect(session.correctCount, 1);
    expect(session.answered, 1);
  });

  test('free text resolves a subject locally without the LLM', () async {
    final api = FakeApi();
    final session = QuizSession(api: api);
    session.beginSubjectSelection();

    expect(session.choosingSubject, true);
    expect(session.messages, isNotEmpty);
    expect(session.messages.first.text, contains('Which test'));

    await session.chooseSubject('air brakes');
    expect(api.resolvedWithoutLlm, true);
    expect(session.choosingSubject, false);
    expect(session.subject?.slug, 'air-brakes');
    expect(session.total, 2);
    expect(session.messages.last.mine, false);
  });

  test('non-English free text resolves locally', () async {
    final api = FakeApi();
    final session = QuizSession(api: api);
    session.beginSubjectSelection();

    await session.chooseSubject('quiero la prueba de frenos de aire');
    expect(api.resolvedWithoutLlm, true);
    expect(session.subject?.slug, 'air-brakes');

    final session2 = QuizSession(api: api);
    session2.beginSubjectSelection();
    await session2.chooseSubject('examen de conocimientos generales');
    expect(session2.subject?.slug, 'general-knowledge');
  });

  test('ambiguous free text falls back to the LLM resolver', () async {
    final api = FakeApi();
    api.resolveResult = 'tanker';
    final session = QuizSession(api: api);
    session.beginSubjectSelection();

    await session.chooseSubject('the one with the big cylinder truck');
    expect(api.resolveCalls, 1);
    expect(session.choosingSubject, false);
    expect(session.subject?.slug, 'tanker');
  });

  test('unknown text keeps the selection phase open with a retry hint', () async {
    final api = FakeApi();
    api.resolveResult = null;
    final session = QuizSession(api: api);
    session.beginSubjectSelection();

    await session.chooseSubject('queria algo distinto');
    expect(api.resolveCalls, 1);
    expect(session.choosingSubject, true);
    expect(session.subject, isNull);
    expect(session.messages.last.text, contains('tap a subject below'));
  });

  test('quizSubjectForText covers slugs, english titles and translations', () {
    expect(quizSubjectForText('air-brakes')?.slug, 'air-brakes');
    expect(quizSubjectForText('air brakes')?.slug, 'air-brakes');
    expect(quizSubjectForText('combination vehicles')?.slug, 'combination-vehicles');
    expect(quizSubjectForText('hazmat')?.slug, 'hazmat');
    expect(quizSubjectForText('school bus')?.slug, 'school-bus');
    expect(quizSubjectForText('pasajeros')?.slug, 'passenger-bus');
    expect(quizSubjectForText('mercancías peligrosas')?.slug, 'hazmat');
    expect(quizSubjectForText('unknown thing'), isNull);
  });
}