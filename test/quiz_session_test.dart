import 'package:aone_ui/features/ai_quiz/quiz/quiz_api.dart';
import 'package:aone_ui/features/ai_quiz/quiz/quiz_controller.dart';
import 'package:aone_ui/features/ai_quiz/quiz/quiz_models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApi extends AiQuizApi {
  FakeApi() : super(base: 'http://unused', workspace: 'ws_1');

  int aiCalls = 0;
  int attemptCalls = 0;

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
}

void main() {
  test('letter answers are scored deterministically and free text hits LLM',
      () async {
    final api = FakeApi();
    final session = QuizSession(api: api);
    await session.start(kQuizSubjects.first);

    expect(session.total, 2);
    expect(session.done, false);

    // Wrong letter (A) → D is correct? no, correct is B → wrong.
    await session.send('A');
    expect(session.wrongCount, 1);
    expect(session.correctCount, 0);
    expect(session.done, false);

    // Voice-style answer "dee" → correct for q2 (D).
    await session.send('dee');
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
    await session.send('the answer is B');
    expect(session.correctCount, 1);
    expect(session.answered, 1);
  });
}