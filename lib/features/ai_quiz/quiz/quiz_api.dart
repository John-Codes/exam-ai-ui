import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'quiz_models.dart';

/// Thin HTTP client for the TestReady CDL exam API used by AI quiz mode.
class AiQuizApi {
  AiQuizApi({String? base, String? workspace})
      : base = base ?? AppConfig.examApiBase,
        workspace = workspace ?? AppConfig.examWorkspace;

  final String base;
  final String workspace;

  Uri _uri(String path, [Map<String, String> query = const {}]) => Uri.parse(
        '$base/api/v1/workspaces/$workspace$path',
      ).replace(queryParameters: query.isEmpty ? null : query);

  Future<List<QuizQuestion>> fetchQuestions({
    required String subject,
    int limit = 50,
  }) async {
    final res = await http
        .get(_uri('/questions', {
          'tag': subject,
          'limit': '$limit',
        }))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('question bank returned HTTP ${res.statusCode}');
    }
    final raw = jsonDecode(res.body) as List<dynamic>;
    final questions = <QuizQuestion>[];
    for (final item in raw) {
      final q = QuizQuestion.fromJson((item as Map<String, dynamic>));
      if (q.stem.trim().isNotEmpty && q.choices.isNotEmpty && q.answerKey.isNotEmpty) {
        questions.add(q);
      }
    }
    return questions;
  }

  /// Ask the AI tutor for an explanation / follow-up. The correct answer is
  /// never sent unless [revealCorrect] is true (scoring stays deterministic
  /// on the client).
  Future<String> aiExplain({
    required QuizQuestion question,
    required String userText,
    required List<Map<String, String>> history,
    bool revealCorrect = false,
  }) async {
    final choices = <String, String>{
      for (final c in question.choices) c.key: c.text,
    };
    final body = {
      'user_text': userText,
      'history': history,
      'context': {
        'subject': question.tags.isNotEmpty ? question.tags.first : null,
        'subject_label': null,
        'stem': question.stem,
        'choices': choices,
        if (revealCorrect && question.answerKey.isNotEmpty)
          'correct_key': question.answerKey.first,
        if (question.explanation != null) 'explanation': question.explanation,
      },
    };
    final res = await http
        .post(
          _uri('/ai/generate'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));
    if (res.statusCode != 200) {
      throw Exception('AI tutor returned HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['response'] as String?)?.trim() ?? '';
  }

  /// Have the LLM map a free-text request (in any language) to a subject slug.
  /// Returns null when the LLM cannot confidently match a subject.
  Future<String?> resolveSubject(String text) async {
    final choices = {
      for (final s in kQuizSubjects) s.slug: s.title,
    };
    final body = {
      'user_text': text,
      'history': <Object>[],
      'context': {
        'subject': null,
        'subject_label': null,
        'stem': 'You are the test selector for a CDL practice quiz app. '
            'Understand what the test-taker says in ANY language (English, '
            'Spanish, French, etc.) and decide which single practice test they '
            'want to take. Reply with ONLY the matching key from this list, or '
            'exactly "none" if nothing matches or it is ambiguous. '
            'Available keys: '
            '${choices.entries.map((e) => '${e.key} = ${e.value}').join('; ')}.',
        'choices': choices,
      },
    };
    final res = await http
        .post(
          _uri('/ai/generate'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final reply = ((data['response'] as String?) ?? '').trim().toLowerCase();
    for (final slug in choices.keys) {
      if (reply.contains(slug)) return slug;
    }
    return null;
  }

  Future<void> recordAttempt({
    required String tag,
    required int total,
    required int correct,
    required bool passed,
    int? durationS,
  }) async {
    try {
      await http.post(
        _uri('/attempts'),
        headers: const {
          'Content-Type': 'application/json',
          'X-User-Id': 'ai_quiz_web',
        },
        body: jsonEncode({
          'tag': tag,
          'total': total,
          'correct': correct,
          'passed': passed,
          'duration_s': durationS,
        }),
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      // Analytics are best-effort; never block the learner on this.
    }
  }
}