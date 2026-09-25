import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/create_pin_screen.dart';
import '../../features/auth/presentation/screens/lock_screen.dart';
import 'vault_activity_detector.dart';

/// Keeps drafts/routes alive, but removes the entire protected navigator from
/// painting, hit testing, focus, and accessibility while the session is locked.
class VaultSessionGate extends StatefulWidget {
  const VaultSessionGate({super.key, required this.home});
  final Widget home;
  @override
  State<VaultSessionGate> createState() => _VaultSessionGateState();
}

class _VaultSessionGateState extends State<VaultSessionGate> {
  final _navigator = GlobalKey<NavigatorState>();
  AuthStateProvider? _auth;
  bool _hasUnlocked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_auth == null) {
      _auth = context.read<AuthStateProvider>();
      WidgetsBinding.instance.addObserver(_auth!);
    }
  }

  @override
  void dispose() {
    if (_auth != null) WidgetsBinding.instance.removeObserver(_auth!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final locked = auth.isLocked || !auth.initialized || auth.needsPinSetup;
    if (!locked) _hasUnlocked = true;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasUnlocked)
          Offstage(
            offstage: locked,
            child: ExcludeFocus(
              excluding: locked,
              child: TickerMode(
                enabled: !locked,
                child: NavigatorPopHandler<Object?>(
                  enabled: !locked,
                  onPopWithResult: (result) =>
                      _navigator.currentState!.pop(result),
                  child: VaultActivityDetector(
                    child: Navigator(
                      key: _navigator,
                      onGenerateRoute: (_) =>
                          MaterialPageRoute<void>(builder: (_) => widget.home),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (locked)
          auth.needsPinSetup && auth.initialized
              ? const CreatePinScreen()
              : const LockScreen(),
      ],
    );
  }
}
