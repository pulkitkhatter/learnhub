import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../state/theme_controller.dart';

/// Dark-mode toggle + account menu shared by the top-level screens.
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final auth = context.watch<AuthController>();
    final dark = theme.isDark(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
        onPressed: () => theme.toggle(context),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (c, a) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: c)),
          child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              key: ValueKey(dark)),
        ),
      ),
      if (auth.user != null)
        PopupMenuButton<String>(
          tooltip: 'Account',
          onSelected: (_) => auth.logout(),
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Text('${auth.user!.name}\n${auth.user!.email}'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout),
                title: Text('Sign out'),
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              radius: 16,
              child: Text(auth.user!.name.characters.first.toUpperCase()),
            ),
          ),
        ),
      const SizedBox(width: 8),
    ]);
  }
}
