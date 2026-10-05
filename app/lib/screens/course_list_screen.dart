import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../state/auth_controller.dart';
import '../state/courses_controller.dart';
import '../widgets/animated_progress.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/course_card.dart';
import '../widgets/state_views.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String _query = '';

  List<CourseSummary> _filter(List<CourseSummary> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.summary.toLowerCase().contains(q) ||
            c.level.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CoursesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnHub', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: const [AppBarActions()],
      ),
      body: switch (controller.status) {
        LoadStatus.loading => const _LoadingGrid(),
        LoadStatus.error =>
          ErrorView(message: controller.error ?? 'Unknown error', onRetry: controller.load),
        LoadStatus.loaded => RefreshIndicator(
            onRefresh: controller.load,
            child: _buildLoaded(context, controller),
          ),
      },
    );
  }

  Widget _buildLoaded(BuildContext context, CoursesController controller) {
    final courses = _filter(controller.courses);
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);
      final padding = width >= 700 ? 32.0 : 16.0;
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${context.read<AuthController>().user?.name.split(' ').first ?? 'there'}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      _OverallProgress(controller: controller),
                      const SizedBox(height: 20),
                      SearchBar(
                        hintText: 'Search courses',
                        leading: const Icon(Icons.search),
                        elevation: const WidgetStatePropertyAll(0),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (controller.courses.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                title: 'No courses yet',
                body: 'New courses will show up here as soon as they are published.',
              ),
            )
          else if (courses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                title: 'No matching courses',
                body: 'Nothing matches “${_query.trim()}”. Try a different search.',
                action: OutlinedButton(
                    onPressed: () => setState(() => _query = ''),
                    child: const Text('Clear search')),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
              sliver: SliverLayoutBuilder(builder: (context, c) {
                final maxW = 1200 - padding * 2;
                final contentW = (c.crossAxisExtent).clamp(0, maxW).toDouble();
                final side = (c.crossAxisExtent - contentW) / 2;
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 290,
                    ),
                    itemCount: courses.length,
                    itemBuilder: (context, i) {
                      final course = courses[i];
                      return _FadeIn(
                        delay: Duration(milliseconds: 60 * i),
                        child: CourseCard(
                          course: course,
                          progress: controller.progress.of(course.id),
                          bestScore: controller.progress.bestScores[course.id],
                          onTap: () => context.push('/course/${course.id}'),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
        ],
      );
    });
  }
}

class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.controller});

  final CoursesController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = controller.progress;
    final finished =
        controller.courses.where((c) => p.of(c.id).isComplete).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          ProgressRing(value: p.fraction, size: 76),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall progress',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${p.completed} of ${p.total} lessons completed · '
                  '$finished of ${controller.courses.length} courses finished',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                AnimatedProgressBar(value: p.fraction),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 700 ? 2 : 1);
        return GridView.count(
          padding: EdgeInsets.all(c.maxWidth >= 700 ? 32 : 16),
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: columns == 1 ? 1.6 : 1.5,
          children: List.generate(columns * 2, (_) => const SkeletonCard()),
        );
      });
}

/// Fades + slides a child in once, with an optional stagger [delay].
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = const Duration(milliseconds: 350) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
