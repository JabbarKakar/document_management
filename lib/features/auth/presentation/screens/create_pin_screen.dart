import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/vault_page_shell.dart';
import '../providers/auth_state_provider.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await context.read<AuthStateProvider>().setPin(
      _pinController.text,
      _confirmController.text,
    );
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
              Icons.key_rounded,
              size: 56,
              color: scheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Create your PIN',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'At least 4 digits. You will use this to unlock the vault.',
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
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
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
              onPressed: _submit,
              child: const Text('Save and continue'),
            ),
          ],
        ),
      ),
    );
  }
}
