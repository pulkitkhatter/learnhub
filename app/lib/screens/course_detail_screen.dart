import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/repository.dart';
import '../models/course.dart';
import '../models/progress.dart';
import '../state/courses_controller.dart';
import '../widgets/animated_progress.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/state_views.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseDetail? _course;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final course = await context.read<LearnRepository>().course(widget.courseId);
      if (!mounted) return;
      setState(() => _course = course);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.statusCode == 404 ? 'This course could not be found.' : e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (success != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(success)));
      }
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("Couldn't save: ${e.message}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CoursesController>();
    final course = _course;

    Widget body;
    if (_loading || (controller.status == LoadStatus.loading && course == null)) {
      body = const LoadingView(label: 'Loading course…');
    } else if (_error != null || course == null) {
      body = ErrorView(message: _error ?? 'Course not found', onRetry: _load);
    } else if (controller.status == LoadStatus.error) {
      body = ErrorView(message: controller.error ?? 'Could not load progress', onRetry: controller.load);
    } else {
      body = _Body(
        course: course,
        progress: controller.progress.of(course.id),
        bestScore: controller.progress.bestScores[course.id],
        onToggleLesson: (lesson, done) => _run(
          () => controller.setLessonCompleted(course.id, lesson.id, done),
          success: done ? 'Lesson completed ✓' : null,
        ),
        onToggleCourse: (done) => _run(
          () => controller.setCourseCompleted(course, done),
          success: done ? 'Course completed 🎉' : 'Course marked as not completed',
        ),
        onStartQuiz: () => context.push('/course/${course.id}/quiz'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/')),
        title: Text(course?.title ?? 'Course'),
        actions: const [AppBarActions()],
      ),
      body: body,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.course,
    required this.progress,
    required this.bestScore,
    required this.onToggleLesson,
    required this.onToggleCourse,
    required this.onStartQuiz,
  });

  final CourseDetail course;
  final CourseProgress progress;
  final int? bestScore;
  final void Function(Lesson lesson, bool done) onToggleLesson;
  final void Function(bool done) onToggleCourse;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final pad = constraints.maxWidth >= 700 ? 32.0 : 16.0;

      final header = _Header(course: course);
      final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ProgressCard(course: course, progress: progress, onToggleCourse: onToggleCourse),
        const SizedBox(height: 16),
        _QuizCard(course: course, bestScore: bestScore, onStart: onStartQuiz),
      ]);
      final lessons = _LessonList(
          course: course, progress: progress, onToggle: onToggleLesson);

      return SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: wide
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    header,
                    const SizedBox(height: 24),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: lessons),
                      const SizedBox(width: 24),
                      SizedBox(width: 340, child: side),
                    ]),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    header,
                    const SizedBox(height: 20),
                    side,
                    const SizedBox(height: 24),
                    lessons,
                  ]),
          ),
        ),
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.course});

  final CourseDetail course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Hero(
        tag: 'emoji-${course.id}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: scheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
            child: Text(course.emoji, style: const TextStyle(fontSize: 34)),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            Chip(
                label: Text(course.level),
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
                backgroundColor: scheme.surfaceContainerHighest),
            Chip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: Text(formatMinutes(course.durationMinutes)),
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
                backgroundColor: scheme.surfaceContainerHighest),
          ]),
          const SizedBox(height: 8),
          Text(course.description,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
        ]),
      ),
    ]);
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.course,
    required this.progress,
    required this.onToggleCourse,
  });

  final CourseDetail course;
  final CourseProgress progress;
  final void Function(bool done) onToggleCourse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = progress.isComplete;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            ProgressRing(value: progress.fraction),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your progress',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${progress.completed} of ${course.lessons.length} lessons',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.passthrough,
              alignment: Alignment.center,
              children: [...previous, ?current],
            ),
            child: done
                ? OutlinedButton.icon(
                    key: const ValueKey('undo'),
                    onPressed: () => onToggleCourse(false),
                    icon: const Icon(Icons.undo),
                    label: const Text('Mark course as not completed'),
                  )
                : FilledButton.icon(
                    key: const ValueKey('complete'),
                    onPressed: () => onToggleCourse(true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark course as completed'),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.course, required this.bestScore, required this.onStart});

  final CourseDetail course;
  final int? bestScore;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.quiz_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            Text('Course quiz',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${course.questionCount} multiple-choice questions · '
            '${formatClock(course.quizTimeLimitSeconds)} time limit',
            style: theme.textTheme.bodyMedium,
          ),
          if (bestScore != null) ...[
            const SizedBox(height: 4),
            Text('Best score: $bestScore / ${course.questionCount}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(bestScore == null ? 'Start quiz' : 'Take quiz again'),
          ),
        ]),
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({required this.course, required this.progress, required this.onToggle});

  final CourseDetail course;
  final CourseProgress progress;
  final void Function(Lesson lesson, bool done) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOpen = course.lessons.indexWhere((l) => !progress.isLessonDone(l.id));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lessons',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (course.lessons.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('This course has no lessons yet.')))
      else
        for (final (i, lesson) in course.lessons.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LessonTile(
              index: i,
              lesson: lesson,
              done: progress.isLessonDone(lesson.id),
              initiallyExpanded: i == (firstOpen == -1 ? 0 : firstOpen),
              onToggle: (done) => onToggle(lesson, done),
            ),
          ),
    ]);
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.done,
    required this.initiallyExpanded,
    required this.onToggle,
  });

  final int index;
  final Lesson lesson;
  final bool done;
  final bool initiallyExpanded;
  final void Function(bool done) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('lesson-${lesson.id}'),
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: done
                ? const Icon(Icons.check_circle, key: ValueKey('done'), color: Colors.green, size: 30)
                : CircleAvatar(
                    key: const ValueKey('todo'),
                    radius: 15,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Text('${index + 1}', style: theme.textTheme.labelLarge),
                  ),
          ),
          title: Text(lesson.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: done ? scheme.onSurfaceVariant : null,
              )),
          subtitle: Text('${lesson.minutes} min${done ? ' · Completed' : ''}'),
          children: [
            Text(lesson.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: 16),
            done
                ? OutlinedButton.icon(
                    onPressed: () => onToggle(false),
                    icon: const Icon(Icons.undo),
                    label: const Text('Mark as not completed'),
                  )
                : FilledButton.icon(
                    onPressed: () => onToggle(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark lesson as completed'),
                  ),
          ],
        ),
      ),
    );
  }
}
