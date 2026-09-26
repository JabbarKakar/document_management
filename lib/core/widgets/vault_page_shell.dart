import 'package:flutter/material.dart';
import 'vault_identity.dart';

/// Soft vertical gradient and optional centered card for auth-style pages.
class VaultPageShell extends StatelessWidget {
  const VaultPageShell({super.key, required this.child, this.useCard = true});

  final Widget child;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final content = useCard
        ? Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(padding: const EdgeInsets.all(28), child: child),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          );

    return VaultAtmosphere(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
