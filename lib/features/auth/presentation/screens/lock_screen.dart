import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Vault locked',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to unlock',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 8,
                onSubmitted: (_) => _submitPin(),
                decoration: InputDecoration(
                  labelText: 'PIN',
                  border: const OutlineInputBorder(),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submitPin(),
                  child: const Text('Unlock'),
                ),
              ),
              if (provider.biometricAvailable && provider.biometricEnrolled) ...[
                const SizedBox(height: 16),
                if (provider.biometricEnabled)
                  OutlinedButton.icon(
                    onPressed: () => _unlockWithBiometrics(),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use fingerprint / Face ID'),
                  )
                else
                  Column(
                    children: [
                      Text(
                        'Use fingerprint or Face ID to unlock?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _turnOnBiometric(),
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Turn on'),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
