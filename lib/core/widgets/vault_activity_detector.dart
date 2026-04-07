import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_state_provider.dart';

/// Records user interactions so auto-lock is based on real activity (Module 21).
class VaultActivityDetector extends StatelessWidget {
  const VaultActivityDetector({super.key, required this.child});

  final Widget child;

  Future<void> _record(BuildContext context) async {
    final auth = context.read<AuthStateProvider>();
    // IMPORTANT: enforce auto-lock *before* recording activity, otherwise a tap
    // after the timeout would refresh [_lastActivityAt] and prevent locking.
    await auth.enforceAutoLockIfNeeded();
    if (auth.isLocked) return;
    auth.recordActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => unawaited(_record(context)),
      onPointerMove: (_) => unawaited(_record(context)),
      onPointerSignal: (_) => unawaited(_record(context)),
      child: child,
    );
  }
}

