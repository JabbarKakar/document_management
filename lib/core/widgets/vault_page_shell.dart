import 'package:flutter/material.dart';

/// Soft vertical gradient and optional centered card for auth-style pages.
class VaultPageShell extends StatelessWidget {
  const VaultPageShell({
    super.key,
    required this.child,
    this.useCard = true,
  });

  final Widget child;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = useCard
        ? Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: child,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.45),
            scheme.surface,
            scheme.secondaryContainer.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.12 : 0.2,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: content,
          ),
        ),
      ),
    );
  }
}
