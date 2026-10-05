import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/core/api_client.dart';
import 'package:learnhub/core/repository.dart';
import 'package:learnhub/models/quiz.dart';
import 'package:learnhub/state/quiz_controller.dart';

class _FakeRepo extends LearnRepository {
  _FakeRepo() : super(ApiClient());

  bool failSubmit = false;
  List<int?>? submitted;

  @override
  Future<Quiz> quiz(String courseId) async => const Quiz(timeLimitSeconds: 10, questions: [
        QuizQuestion(question: 'Q1', options: ['a', 'b']),
        QuizQuestion(question: 'Q2', options: ['a', 'b']),
      ]);

  @override
  Future<QuizResult> submitQuiz(String courseId, List<int?> answers, int durationSeconds) async {
    if (failSubmit) throw ApiException('boom');
    submitted = answers;
    return QuizResult(score: 1, total: 2, durationSeconds: durationSeconds, bestScore: 1, review: const []);
  }
}

void main() {
  test('navigates, answers and submits', () async {
    final repo = _FakeRepo();
    final c = QuizController(repo, 'x');
    await c.load();
    expect(c.phase, QuizPhase.intro);
    c.start();
    expect(c.isFirst, isTrue);
    c.select(1);
    c.next();
    expect(c.isLast, isTrue);
    c.previous();
    expect(c.answers, [1, null]);
    await c.submit();
    expect(c.phase, QuizPhase.result);
    expect(repo.submitted, [1, null]);
    c.dispose();
  });

  test('retry resets answers and timer', () async {
    final c = QuizController(_FakeRepo(), 'x');
    await c.load();
    c.start();
    c.select(0);
    await c.submit();
    c.retry();
    expect(c.phase, QuizPhase.running);
    expect(c.answers, [null, null]);
    expect(c.remainingSeconds, 10);
    c.dispose();
  });

  test('failed submit keeps answers and can be retried', () async {
    final repo = _FakeRepo()..failSubmit = true;
    final c = QuizController(repo, 'x');
    await c.load();
    c.start();
    c.select(1);
    await c.submit();
    expect(c.phase, QuizPhase.submitError);
    expect(c.answers[0], 1);
    repo.failSubmit = false;
    await c.submit();
    expect(c.phase, QuizPhase.result);
    c.dispose();
  });

  test('auto-submits when the timer runs out', () {
    fakeAsync((async) {
      final repo = _FakeRepo();
      final c = QuizController(repo, 'x');
      c.load();
      async.flushMicrotasks();
      c.start();
      c.select(0);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(c.timedOut, isTrue);
      expect(c.phase, QuizPhase.result);
      expect(repo.submitted, [0, null]);
      c.dispose();
    });
  });
}
