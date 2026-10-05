import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/models/progress.dart';

void main() {
  test('overall progress is recomputed when a lesson is toggled', () {
    const p = Progress(
      courses: {
        'a': CourseProgress(completedLessonIds: {}, completed: 0, total: 4),
        'b': CourseProgress(completedLessonIds: {}, completed: 0, total: 6),
      },
      completed: 0,
      total: 10,
      bestScores: {},
    );
    final next = p.withCourse('a', p.of('a').withLesson('l1', true));
    expect(next.completed, 1);
    expect(next.total, 10);
    expect(next.of('a').fraction, 0.25);
    expect(next.fraction, closeTo(0.1, 1e-9));

    final all = next.withCourse('a', next.of('a').withAll(['l1', 'l2', 'l3', 'l4'], true));
    expect(all.of('a').isComplete, isTrue);
    expect(all.completed, 4);
    expect(all.withCourse('a', all.of('a').withAll([], false)).completed, 0);
  });
}
