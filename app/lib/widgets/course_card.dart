import 'package:flutter/material.dart';

import '../core/course_icons.dart';
import '../core/format.dart';
import '../models/course.dart';
import '../models/progress.dart';
import 'animated_progress.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.progress,
    this.bestScore,
    required this.onTap,
  });

  final CourseSummary course;
  final CourseProgress progress;
  final int? bestScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = progress.isComplete;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Hero(
                  tag: 'course-icon-${course.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(courseIcon(course.icon), size: 28, color: scheme.onPrimaryContainer),
                    ),
                  ),
                ),
                const Spacer(),
                if (done)
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    label: const Text('Completed'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: Colors.green.withValues(alpha: 0.12),
                  )
                else
                  Chip(
                    label: Text(course.level),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
              ]),
              const SizedBox(height: 16),
              Text(course.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(course.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              Wrap(spacing: 14, runSpacing: 4, children: [
                _Meta(Icons.menu_book_outlined, '${course.lessonCount} lessons'),
                _Meta(Icons.schedule, formatMinutes(course.durationMinutes)),
                _Meta(Icons.quiz_outlined,
                    bestScore == null
                        ? '${course.questionCount} questions'
                        : 'Best ${bestScore!}/${course.questionCount}'),
              ]),
              const SizedBox(height: 16),
              AnimatedProgressBar(value: progress.fraction),
              const SizedBox(height: 6),
              Text('${progress.completed} of ${course.lessonCount} lessons done',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
    ]);
  }
}
