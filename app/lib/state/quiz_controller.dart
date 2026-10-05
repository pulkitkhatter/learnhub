import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/repository.dart';
import '../models/quiz.dart';

enum QuizPhase { loading, error, intro, running, submitting, submitError, result }

/// Drives one quiz session: loading, countdown timer, navigation, submission
/// and retry.
class QuizController extends ChangeNotifier {
  QuizController(this._repo, this.courseId);

  final LearnRepository _repo;
  final String courseId;

  QuizPhase phase = QuizPhase.loading;
  String? error;
  Quiz? quiz;
  QuizResult? result;

  List<int?> answers = [];
  int current = 0;
  int remainingSeconds = 0;
  bool timedOut = false;

  Timer? _timer;
  bool _disposed = false;

  List<QuizQuestion> get questions => quiz?.questions ?? const [];
  int get answeredCount => answers.where((a) => a != null).length;
  bool get isFirst => current == 0;
  bool get isLast => current == questions.length - 1;
  int get elapsedSeconds => (quiz?.timeLimitSeconds ?? 0) - remainingSeconds;

  Future<void> load() async {
    _timer?.cancel();
    phase = QuizPhase.loading;
    error = null;
    notifyListeners();
    try {
      quiz = await _repo.quiz(courseId);
      _reset();
      phase = QuizPhase.intro;
    } on ApiException catch (e) {
      error = e.message;
      phase = QuizPhase.error;
    }
    notifyListeners();
  }

  void _reset() {
    answers = List<int?>.filled(questions.length, null);
    current = 0;
    timedOut = false;
    result = null;
    remainingSeconds = quiz!.timeLimitSeconds;
  }

  void start() {
    _reset();
    phase = QuizPhase.running;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (phase != QuizPhase.running) return;
    remainingSeconds--;
    if (remainingSeconds <= 0) {
      remainingSeconds = 0;
      timedOut = true;
      submit();
    } else {
      notifyListeners();
    }
  }

  void select(int option) {
    if (phase != QuizPhase.running) return;
    answers[current] = option;
    notifyListeners();
  }

  void next() => goTo(current + 1);
  void previous() => goTo(current - 1);

  void goTo(int index) {
    if (phase != QuizPhase.running || index < 0 || index >= questions.length) return;
    current = index;
    notifyListeners();
  }

  /// Submits the current answers (also used for auto-submit when time is up
  /// and for retrying a failed submission — answers are kept).
  Future<void> submit() async {
    if (phase != QuizPhase.running && phase != QuizPhase.submitError) return;
    _timer?.cancel();
    phase = QuizPhase.submitting;
    error = null;
    notifyListeners();
    try {
      final res = await _repo.submitQuiz(courseId, answers, elapsedSeconds);
      if (_disposed) return;
      result = res;
      phase = QuizPhase.result;
    } on ApiException catch (e) {
      if (_disposed) return;
      error = e.message;
      phase = QuizPhase.submitError;
    }
    notifyListeners();
  }

  /// Starts over with a fresh attempt.
  void retry() => start();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
