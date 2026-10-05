class CourseProgress {
  const CourseProgress({
    required this.completedLessonIds,
    required this.completed,
    required this.total,
  });

  static const empty =
      CourseProgress(completedLessonIds: <String>{}, completed: 0, total: 0);

  factory CourseProgress.fromJson(Map<String, dynamic> json) => CourseProgress(
        completedLessonIds:
            (json['completedLessonIds'] as List).cast<String>().toSet(),
        completed: json['completed'] as int,
        total: json['total'] as int,
      );

  final Set<String> completedLessonIds;
  final int completed;
  final int total;

  double get fraction => total == 0 ? 0 : completed / total;
  bool get isComplete => total > 0 && completed == total;

  CourseProgress withLesson(String lessonId, bool done) {
    final ids = {...completedLessonIds};
    done ? ids.add(lessonId) : ids.remove(lessonId);
    return CourseProgress(
        completedLessonIds: ids, completed: ids.length, total: total);
  }

  CourseProgress withAll(Iterable<String> lessonIds, bool done) {
    final ids = done ? lessonIds.toSet() : <String>{};
    return CourseProgress(
        completedLessonIds: ids, completed: ids.length, total: total);
  }

  bool isLessonDone(String lessonId) => completedLessonIds.contains(lessonId);
}

class Progress {
  const Progress({
    required this.courses,
    required this.completed,
    required this.total,
    required this.bestScores,
  });

  static const empty =
      Progress(courses: {}, completed: 0, total: 0, bestScores: {});

  factory Progress.fromJson(Map<String, dynamic> json) {
    final overall = json['overall'] as Map<String, dynamic>;
    return Progress(
      courses: (json['courses'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, CourseProgress.fromJson(v as Map<String, dynamic>)),
      ),
      completed: overall['completed'] as int,
      total: overall['total'] as int,
      bestScores: (json['bestScores'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int)),
    );
  }

  final Map<String, CourseProgress> courses;
  final int completed;
  final int total;
  final Map<String, int> bestScores;

  double get fraction => total == 0 ? 0 : completed / total;

  /// Returns a copy with [courseId]'s progress replaced and totals recomputed.
  Progress withCourse(String courseId, CourseProgress updated) {
    final next = {...courses, courseId: updated};
    return Progress(
      courses: next,
      completed: next.values.fold(0, (sum, c) => sum + c.completed),
      total: next.values.fold(0, (sum, c) => sum + c.total),
      bestScores: bestScores,
    );
  }

  CourseProgress of(String courseId) => courses[courseId] ?? CourseProgress.empty;
}
