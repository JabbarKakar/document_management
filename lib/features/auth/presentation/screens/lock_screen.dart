import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/vault_page_shell.dart';
import '../../../../core/widgets/vault_identity.dart';
import '../providers/auth_state_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  bool _recovering = false;
  bool _obscure = true;

  @override
  void dispose() {
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthStateProvider>();
    if (auth.isBusy) return;
    final ok = _recovering
        ? await auth.resetPinWithDevice(_pin.text, _confirmation.text)
        : await auth.unlockWithPin(_pin.text);
    if (ok && mounted) {
      _pin.clear();
      _confirmation.clear();
      setState(() => _recovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      body: VaultPageShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: VaultMark(size: 120, orbits: true)),
            const Center(child: VaultEyebrow('Your private space')),
            const SizedBox(height: 20),
            Text(
              _recovering ? 'Reset vault PIN' : 'Vault locked',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              _recovering
                  ? 'Choose a new 4–8 digit PIN. Your device passcode, fingerprint, or Face ID must verify this change. Your documents will stay intact.'
                  : 'Enter your vault PIN or use your device passcode, fingerprint, or Face ID.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (auth.initialized) ...[
              TextField(
                controller: _pin,
                enabled: !auth.isBusy,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                // Legacy PINs were not length/digit restricted. Keep them usable
                // for unlock; only newly created PINs use the stricter policy.
                maxLength: _recovering ? 8 : null,
                inputFormatters: _recovering
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: _recovering ? 'New PIN' : 'PIN',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show PIN' : 'Hide PIN',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              if (_recovering) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmation,
                  enabled: !auth.isBusy,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Confirm new PIN',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ],
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  auth.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isBusy
                  ? null
                  : (auth.initialized ? _submit : auth.init),
              child: Text(
                auth.isBusy
                    ? 'Please wait…'
                    : !auth.initialized
                    ? 'Retry'
                    : _recovering
                    ? 'Verify device and reset PIN'
                    : 'Unlock',
              ),
            ),
            if (auth.initialized &&
                auth.deviceAuthAvailable &&
                !_recovering) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: auth.isBusy ? null : auth.unlockWithDevice,
                icon: const Icon(Icons.phonelink_lock_rounded),
                label: const Text('Use device unlock'),
              ),
              TextButton(
                onPressed: auth.isBusy
                    ? null
                    : () => setState(() {
                        _pin.clear();
                        _recovering = true;
                      }),
                child: const Text('Forgot PIN?'),
              ),
            ],
            if (_recovering)
              TextButton(
                onPressed: auth.isBusy
                    ? null
                    : () => setState(() {
                        _recovering = false;
                        _pin.clear();
                        _confirmation.clear();
                      }),
                child: const Text('Back to unlock'),
              ),
            if (auth.initialized && !auth.deviceAuthAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'If you cannot use your PIN or device unlock, restore a recovery backup into a new installation. The backup password is required.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
