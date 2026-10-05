import 'package:flutter/material.dart';

/// Shared centred message used for loading, empty and error states.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(body!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Message(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        body: message,
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.body, this.action});

  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _Message(
      icon: Icons.search_off_rounded, title: title, body: body, action: action);
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!),
          ],
        ]),
      );
}

/// Pulsing placeholder card used while the course list loads.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(
        width: w,
        height: h,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)));
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(48, 48),
              const SizedBox(height: 16),
              bar(180, 20),
              const SizedBox(height: 10),
              bar(double.infinity, 14),
              const SizedBox(height: 6),
              bar(220, 14),
              const Spacer(),
              bar(double.infinity, 8),
            ],
          ),
        ),
      ),
    );
  }
}
