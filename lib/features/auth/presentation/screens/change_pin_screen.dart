import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/vault_page_shell.dart';
import '../providers/auth_state_provider.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthStateProvider>();
    setState(() => _busy = true);
    final err = await auth.changePin(
      currentPin: _currentController.text,
      newPin: _newController.text,
      confirmPin: _confirmController.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated')),
      );
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change PIN'),
      ),
      body: VaultPageShell(
        useCard: false,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose a new PIN you have not used elsewhere.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _currentController,
                  obscureText: _obscure,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current PIN',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newController,
                  obscureText: _obscure,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm new PIN',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Text('Save new PIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
