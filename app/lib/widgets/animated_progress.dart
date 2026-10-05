import 'package:flutter/material.dart';

/// Linear progress bar that animates smoothly to new values.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: scheme.surfaceContainerHighest,
          color: v >= 1 ? Colors.green : scheme.primary,
        ),
      ),
    );
  }
}

/// Circular progress ring with a percentage label in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 72});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: size / 9,
              strokeCap: StrokeCap.round,
              backgroundColor: scheme.surfaceContainerHighest,
              color: v >= 1 ? Colors.green : scheme.primary,
            ),
          ),
          Text('${(v * 100).round()}%',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
