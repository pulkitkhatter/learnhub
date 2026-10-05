import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/repository.dart';
import '../models/quiz.dart';
import '../state/courses_controller.dart';
import '../state/quiz_controller.dart';
import '../widgets/animated_progress.dart';
import '../widgets/state_views.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => QuizController(ctx.read<LearnRepository>(), courseId)..load(),
      child: _QuizView(courseId: courseId),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView({required this.courseId});

  final String courseId;

  void _exit(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/course/$courseId');

  Future<bool> _confirmLeave(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Leave the quiz?'),
          content: const Text('Your answers will be lost and the timer will stop.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep going')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizController>();
    final inProgress = quiz.phase == QuizPhase.running ||
        quiz.phase == QuizPhase.submitting ||
        quiz.phase == QuizPhase.submitError;

    Widget body = switch (quiz.phase) {
      QuizPhase.loading => const LoadingView(label: 'Loading quiz…'),
      QuizPhase.error => ErrorView(message: quiz.error ?? 'Unknown error', onRetry: quiz.load),
      QuizPhase.intro => _Intro(quiz: quiz),
      QuizPhase.running => _Question(quiz: quiz),
      QuizPhase.submitting => const LoadingView(label: 'Scoring your answers…'),
      QuizPhase.submitError => ErrorView(
          message: '${quiz.error ?? 'Could not submit'}\nYour answers are safe — try again.',
          onRetry: quiz.submit),
      QuizPhase.result => _Result(
          quiz: quiz,
          onRetry: quiz.retry,
          onBack: () => _exit(context),
        ),
    };

    // Refresh the best score on the list/detail once a result exists.
    if (quiz.phase == QuizPhase.result) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<CoursesController>().refreshProgress();
      });
    }

    return PopScope(
      canPop: !inProgress,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave(context) && context.mounted) _exit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close quiz',
            onPressed: () async {
              if (!inProgress || await _confirmLeave(context)) {
                if (context.mounted) _exit(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(key: ValueKey(quiz.phase), child: body),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Intro ─────────────────────────

class _Intro extends StatelessWidget {
  const _Intro({required this.quiz});

  final QuizController quiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          ]),
        );
    return ListView(padding: const EdgeInsets.all(24), children: [
      Icon(Icons.quiz_rounded, size: 64, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      Text('Ready for the quiz?',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            row(Icons.help_outline, '${quiz.questions.length} multiple-choice questions'),
            row(Icons.timer_outlined,
                '${formatClock(quiz.quiz!.timeLimitSeconds)} to finish — it auto-submits when time is up'),
            row(Icons.swap_horiz, 'Move back and forth between questions freely'),
            row(Icons.replay, 'Retry as many times as you like'),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: quiz.start,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start quiz'),
      ),
    ]);
  }
}

// ───────────────────────── Question ─────────────────────────

class _Question extends StatelessWidget {
  const _Question({required this.quiz});

  final QuizController quiz;

  Future<void> _finish(BuildContext context) async {
    final missing = quiz.questions.length - quiz.answeredCount;
    if (missing > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submit with unanswered questions?'),
          content: Text('You have $missing unanswered '
              'question${missing == 1 ? '' : 's'}. They will count as incorrect.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Go back')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit')),
          ],
        ),
      );
      if (ok != true) return;
    }
    quiz.submit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final question = quiz.questions[quiz.current];
    final low = quiz.remainingSeconds <= 30;
    final timerColor = low ? scheme.error : scheme.onSurface;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(children: [
          Row(children: [
            Text('Question ${quiz.current + 1} of ${quiz.questions.length}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Semantics(
              label: 'Time remaining ${formatClock(quiz.remainingSeconds)}',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: low ? scheme.errorContainer : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.timer_outlined, size: 18, color: timerColor),
                  const SizedBox(width: 6),
                  Text(formatClock(quiz.remainingSeconds),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: timerColor,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          AnimatedProgressBar(value: (quiz.current + 1) / quiz.questions.length, height: 6),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(quiz.current),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(question.question,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.35)),
                const SizedBox(height: 20),
                for (final (i, option) in question.options.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      letter: String.fromCharCode(65 + i),
                      text: option,
                      selected: quiz.answers[quiz.current] == i,
                      onTap: () => quiz.select(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // Jump-to dots show which questions are answered.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          for (var i = 0; i < quiz.questions.length; i++)
            Tooltip(
              message: 'Question ${i + 1}${quiz.answers[i] != null ? ' (answered)' : ''}',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => quiz.goTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == quiz.current
                        ? scheme.primary
                        : (quiz.answers[i] != null
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest),
                    border: i == quiz.current ? null : Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text('${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: i == quiz.current ? scheme.onPrimary : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: quiz.isFirst ? null : quiz.previous,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: quiz.isLast
                ? FilledButton.icon(
                    onPressed: () => _finish(context),
                    icon: const Icon(Icons.flag_rounded),
                    label: const Text('Finish'),
                  )
                : FilledButton.icon(
                    onPressed: quiz.next,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
          ),
        ]),
      ),
    ]);
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: selected ? scheme.primary : scheme.surfaceContainerHighest,
                foregroundColor: selected ? scheme.onPrimary : scheme.onSurface,
                child: Text(letter,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: selected ? scheme.onPrimary : scheme.onSurface)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Result ─────────────────────────

class _Result extends StatelessWidget {
  const _Result({required this.quiz, required this.onRetry, required this.onBack});

  final QuizController quiz;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = quiz.result!;
    final (icon, headline) = switch (r.percent) {
      100 => (Icons.emoji_events_rounded, 'Perfect score!'),
      >= 70 => (Icons.thumb_up_alt_rounded, 'Great job!'),
      >= 40 => (Icons.trending_up_rounded, 'Good effort'),
      _ => (Icons.auto_stories_rounded, 'Keep practising'),
    };

    Widget stat(IconData icon, Color color, String value, String label) => Expanded(
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        );

    return ListView(padding: const EdgeInsets.all(20), children: [
      if (quiz.timedOut)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.timer_off_outlined, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text("Time's up! Your answers so far were submitted automatically.",
                  style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ]),
        ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Icon(icon, size: 48, color: scheme.primary),
            const SizedBox(height: 8),
            Text(headline,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ProgressRing(value: r.fraction, size: 120),
            const SizedBox(height: 12),
            Text('You scored ${r.score} out of ${r.total}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            Row(children: [
              stat(Icons.check_circle, Colors.green, '${r.score}', 'Correct'),
              stat(Icons.cancel, scheme.error, '${r.incorrect}', 'Incorrect'),
              stat(Icons.timer_outlined, scheme.primary, formatClock(r.durationSeconds), 'Time'),
              stat(Icons.emoji_events_outlined, Colors.amber.shade700,
                  '${r.bestScore}/${r.total}', 'Best'),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to course'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.replay),
            label: const Text('Retry quiz'),
          ),
        ),
      ]),
      const SizedBox(height: 28),
      Text('Review your answers',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      for (final (i, item) in r.review.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ReviewCard(index: i, item: item),
        ),
    ]);
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.index, required this.item});

  final int index;
  final QuestionReview item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ok = item.isCorrect;
    final accent = ok ? Colors.green : scheme.error;

    Widget answerLine(String label, String text, Color color, IconData icon) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: text),
              ])),
            ),
          ]),
        );

    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 4)),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ok ? Icons.check_circle : Icons.cancel, color: accent),
            const SizedBox(width: 8),
            Text('Question ${index + 1} · ${ok ? 'Correct' : (item.isUnanswered ? 'Unanswered' : 'Incorrect')}',
                style: theme.textTheme.labelLarge?.copyWith(color: accent, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(item.question,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (!ok)
            answerLine(
              'Your answer',
              item.isUnanswered ? 'No answer given' : item.options[item.selectedIndex!],
              scheme.error,
              Icons.close,
            ),
          answerLine('Correct answer', item.options[item.correctIndex], Colors.green, Icons.check),
          const SizedBox(height: 10),
          Text(item.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
