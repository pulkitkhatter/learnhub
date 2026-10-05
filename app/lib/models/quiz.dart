class QuizQuestion {
  const QuizQuestion({required this.question, required this.options});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
      );

  final String question;
  final List<String> options;
}

class Quiz {
  const Quiz({required this.timeLimitSeconds, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        timeLimitSeconds: json['timeLimitSeconds'] as int,
        questions: (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  final int timeLimitSeconds;
  final List<QuizQuestion> questions;
}

class QuestionReview {
  const QuestionReview({
    required this.question,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuestionReview.fromJson(Map<String, dynamic> json) => QuestionReview(
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
        selectedIndex: json['selectedIndex'] as int?,
        correctIndex: json['correctIndex'] as int,
        isCorrect: json['isCorrect'] as bool,
        explanation: json['explanation'] as String,
      );

  final String question;
  final List<String> options;
  final int? selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String explanation;

  bool get isUnanswered => selectedIndex == null;
}

class QuizResult {
  const QuizResult({
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.bestScore,
    required this.review,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        score: json['score'] as int,
        total: json['total'] as int,
        durationSeconds: json['durationSeconds'] as int,
        bestScore: json['bestScore'] as int,
        review: (json['review'] as List)
            .map((r) => QuestionReview.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  final int score;
  final int total;
  final int durationSeconds;
  final int bestScore;
  final List<QuestionReview> review;

  double get fraction => total == 0 ? 0 : score / total;
  int get percent => (fraction * 100).round();
  int get incorrect => total - score;
}
