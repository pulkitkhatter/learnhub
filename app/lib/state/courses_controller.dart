import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/repository.dart';
import '../models/course.dart';
import '../models/progress.dart';

enum LoadStatus { loading, loaded, error }

/// Holds the course catalogue plus the signed-in user's progress.
class CoursesController extends ChangeNotifier {
  CoursesController(this._repo);

  final LearnRepository _repo;

  LoadStatus status = LoadStatus.loading;
  String? error;
  List<CourseSummary> courses = const [];
  Progress progress = Progress.empty;

  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_repo.courses(), _repo.progress()]);
      courses = results[0] as List<CourseSummary>;
      progress = results[1] as Progress;
      status = LoadStatus.loaded;
    } on ApiException catch (e) {
      error = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Refreshes progress/best scores quietly (e.g. after finishing a quiz).
  Future<void> refreshProgress() async {
    try {
      progress = await _repo.progress();
      notifyListeners();
    } on ApiException {
      // Non-fatal: stale numbers are better than an error screen.
    }
  }

  /// Optimistically updates the UI, then syncs; rolls back and rethrows on failure.
  Future<void> setLessonCompleted(String courseId, String lessonId, bool done) =>
      _optimistic(
        progress.withCourse(courseId, progress.of(courseId).withLesson(lessonId, done)),
        () => _repo.setLessonCompleted(courseId, lessonId, done),
      );

  Future<void> setCourseCompleted(CourseDetail course, bool done) => _optimistic(
        progress.withCourse(course.id,
            progress.of(course.id).withAll(course.lessons.map((l) => l.id), done)),
        () => _repo.setCourseCompleted(course.id, done),
      );

  Future<void> _optimistic(Progress next, Future<Progress> Function() request) async {
    final previous = progress;
    progress = next;
    notifyListeners();
    try {
      progress = await request();
    } on ApiException {
      progress = previous;
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }
}
