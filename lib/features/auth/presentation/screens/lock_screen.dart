import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/vault_page_shell.dart';
import '../providers/auth_state_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text;
    if (pin.isEmpty) return;
    final ok = await context.read<AuthStateProvider>().unlockWithPin(pin);
    if (ok && mounted) {
      _pinController.clear();
    }
  }

  Future<void> _unlockWithBiometrics() async {
    await context.read<AuthStateProvider>().unlockWithBiometrics();
  }

  Future<void> _turnOnBiometric() async {
    await context.read<AuthStateProvider>().enableBiometricAndUnlock();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthStateProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: VaultPageShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 56,
              color: scheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Vault locked',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to continue',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              maxLength: 8,
              onSubmitted: (_) => _submitPin(),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'PIN',
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePin = !_obscurePin),
                ),
              ),
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                provider.errorMessage!,
                style: textTheme.bodySmall?.copyWith(color: scheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitPin,
              child: const Text('Unlock'),
            ),
            if (provider.biometricAvailable && provider.biometricEnrolled) ...[
              const SizedBox(height: 12),
              if (provider.biometricEnabled)
                OutlinedButton.icon(
                  onPressed: _unlockWithBiometrics,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Use biometrics'),
                )
              else
                Column(
                  children: [
                    Text(
                      'Unlock faster next time with biometrics',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _turnOnBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Turn on'),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
