import 'package:flutter/material.dart';

import '../../../../core/widgets/vault_identity.dart';

/// A compact, honest overview of the whole vault, independent of list filters.
class VaultOverview extends StatelessWidget {
  const VaultOverview({
    super.key,
    required this.documents,
    required this.attention,
    required this.onAttention,
  });
  final int documents;
  final int attention;
  final VoidCallback onAttention;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.primary.withValues(alpha: .22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.surface,
            scheme.tertiaryContainer.withValues(alpha: .5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VaultEyebrow('Personal • Offline'),
                    const SizedBox(height: 12),
                    Text(
                      'Life, organized.',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$documents ${documents == 1 ? 'document' : 'documents'} stored locally.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 360 &&
                  MediaQuery.textScalerOf(context).scale(16) < 24)
                const VaultMark(size: 88, orbits: true),
            ],
          ),
          if (attention > 0) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAttention,
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: Text(
                '$attention ${attention == 1 ? 'expiry needs' : 'expiries need'} attention',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
