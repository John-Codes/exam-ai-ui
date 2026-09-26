/// Subject catalog + question bank shapes shared by the AI quiz engine.
/// Mirrors the live exam-api `/questions` public schema.
library;

class QuizSubject {
  const QuizSubject({
    required this.slug,
    required this.title,
    required this.abbr,
    required this.description,
  });

  final String slug;
  final String title;
  final String abbr;
  final String description;
}

const kQuizSubjects = <QuizSubject>[
  QuizSubject(
    slug: 'general-knowledge',
    title: 'General Knowledge',
    abbr: 'GK',
    description:
        'The core written test every CDL applicant must pass. Covers safe driving, vehicle inspection, and basic road rules.',
  ),
  QuizSubject(
    slug: 'air-brakes',
    title: 'Air Brakes',
    abbr: 'AB',
    description:
        'Required for vehicles with air brake systems. Air brake theory, components, and troubleshooting.',
  ),
  QuizSubject(
    slug: 'combination-vehicles',
    title: 'Combination Vehicles',
    abbr: 'CV',
    description:
        'Essential for Class A drivers. Tractor-trailer handling, coupling, and braking on grades.',
  ),
  QuizSubject(
    slug: 'tanker',
    title: 'Tanker Endorsement',
    abbr: 'TK',
    description: 'Required to haul liquid cargo in bulk. Liquid surge, braking, and emergencies.',
  ),
  QuizSubject(
    slug: 'hazmat',
    title: 'Hazmat Endorsement',
    abbr: 'HZ',
    description: 'Required for transporting hazardous materials. DOT rules, placarding, safety.',
  ),
  QuizSubject(
    slug: 'passenger-bus',
    title: 'Passenger Endorsement',
    abbr: 'PB',
    description: 'Endorsement for transporting passengers. Passenger safety and procedures.',
  ),
  QuizSubject(
    slug: 'school-bus',
    title: 'School Bus Endorsement',
    abbr: 'SB',
    description: 'Endorsement for transporting students. Danger zones and the eight-light system.',
  ),
];

QuizSubject? quizSubjectForSlug(String? slug) {
  if (slug == null || slug.isEmpty) return null;
  for (final s in kQuizSubjects) {
    if (s.slug == slug) return s;
  }
  return null;
}

const _kSubjectKeywords = <String, List<String>>{
  'general-knowledge': <String>['general', 'knowledge', 'gk', 'conocimient', 'general'],
  'air-brakes': <String>['air', 'brake', 'freno', 'frenos', 'aire', 'ab'],
  'combination-vehicles': <String>['combination', 'combinacion', 'tractor-trailer', 'trailer', 'cv'],
  'tanker': <String>['tanker', 'tanque', 'cisterna', 'tk'],
  'hazmat': <String>['hazmat', 'hazard', 'dangerous', 'peligros', 'materiales', 'mercanc', 'hz'],
  'passenger-bus': <String>['passenger', 'pasajero', 'autobus', 'autobús', 'bus', 'pb'],
  'school-bus': <String>['school', 'student', 'escolar', 'escuela', 'sb'],
};

/// Resolves free text (any language) to a subject. Best-effort keyword match;
/// returns null when ambiguous or unknown so callers can fall back to the LLM.
QuizSubject? quizSubjectForText(String text) {
  final q = text.trim().toLowerCase();
  if (q.isEmpty) return null;
  final clean = q
      .replaceAll(RegExp('[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  for (final s in kQuizSubjects) {
    if (clean == s.slug || clean.contains(s.slug)) return s;
    final title = s.title.toLowerCase();
    if (clean.contains(title) || title.contains(clean)) return s;
  }

  String? best;
  var bestScore = 0;
  for (final s in kQuizSubjects) {
    var score = 0;
    for (final kw in _kSubjectKeywords[s.slug]!) {
      if (clean.contains(kw)) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      best = s.slug;
    } else if (score == bestScore && score > 0) {
      best = null;
    }
  }
  if (best != null && bestScore >= 1) return quizSubjectForSlug(best);
  return null;
}

class QuizChoice {
  const QuizChoice({required this.key, required this.text, this.explanation});

  final String key;
  final String text;
  final String? explanation;

  factory QuizChoice.fromJson(Map<String, dynamic> json) => QuizChoice(
        key: (json['key'] as String?) ?? '',
        text: (json['text'] as String?) ?? '',
        explanation: json['explanation'] as String?,
      );
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.stem,
    this.choices = const [],
    this.answerKey = const [],
    this.explanation,
    this.tags = const [],
  });

  final String id;
  final String stem;
  final List<QuizChoice> choices;
  final List<String> answerKey;
  final String? explanation;
  final List<String> tags;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = (json['choices'] as List<dynamic>?) ?? const [];
    return QuizQuestion(
      id: (json['id'] as String?) ?? '',
      stem: (json['stem'] as String?) ?? '',
      choices: rawChoices
          .whereType<Map<String, dynamic>>()
          .map(QuizChoice.fromJson)
          .toList(),
      answerKey: ((json['answer_key'] as List<dynamic>?) ?? const [])
          .map((k) => k.toString())
          .toList(),
      explanation: json['explanation'] as String?,
      tags: ((json['tags'] as List<dynamic>?) ?? const [])
          .map((t) => t.toString())
          .toList(),
    );
  }

  String? choiceText(String key) {
    for (final c in choices) {
      if (c.key == key) return c.text;
    }
    return null;
  }

  String? explanationForChoice(String key) {
    for (final c in choices) {
      if (c.key == key && (c.explanation?.trim().isNotEmpty ?? false)) {
        return c.explanation;
      }
    }
    return null;
  }
}