import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../auth/presentation/screens/change_pin_screen.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';

/// Module 9 – vault settings: reminders, categories, security, about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _expiryReminders = true;
  int _lockTimeoutSeconds = 60;
  String _versionLabel = '';

  static const _lockOptions = <int, String>{
    30: '30 seconds',
    60: '1 minute',
    300: '5 minutes',
    900: '15 minutes',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final storage = context.read<SecureStorageService>();
    final expiry = await storage.getExpiryRemindersEnabled();
    final timeout = await storage.getLockTimeoutSeconds();
    PackageInfo? info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _expiryReminders = expiry;
      _lockTimeoutSeconds = timeout;
      _versionLabel =
          info == null ? '' : '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _setExpiry(bool value) async {
    final storage = context.read<SecureStorageService>();
    final expiry = context.read<ExpiryReminderService>();
    await storage.setExpiryRemindersEnabled(value);
    await expiry.syncAll();
    if (mounted) setState(() => _expiryReminders = value);
  }

  Future<void> _pickLockTimeout() async {
    final storage = context.read<SecureStorageService>();
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SimpleDialog(
          title: const Text('Auto-lock after inactivity'),
          children: [
            for (final e in _lockOptions.entries)
              ListTile(
                title: Text(e.value),
                trailing: _lockTimeoutSeconds == e.key
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
          ],
        );
      },
    );
    if (picked == null || !mounted) return;
    await storage.setLockTimeoutSeconds(picked);
    setState(() => _lockTimeoutSeconds = picked);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Reminders'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Expiry reminders'),
            subtitle: const Text(
              'Notify at 30, 15, and 7 days before a document expiry date.',
            ),
            value: _expiryReminders,
            onChanged: _setExpiry,
          ),
          const _SectionHeader('Organization'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            subtitle: const Text('Create, rename, or delete categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) => ChangeNotifierProvider.value(
                    value: context.read<CategoryListProvider>(),
                    child: const CategoryManagementScreen(),
                  ),
                ),
              );
            },
          ),
          const _SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-lock timeout'),
            subtitle: Text(
              _lockOptions[_lockTimeoutSeconds] ?? '$_lockTimeoutSeconds s',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickLockTimeout,
          ),
          if (auth.biometricAvailable && auth.biometricEnrolled)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Unlock with biometrics'),
              subtitle: const Text('Fingerprint or Face ID'),
              value: auth.biometricEnabled,
              onChanged: (v) => auth.setBiometricUnlockEnabled(v),
            ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<AuthStateProvider>(),
                    child: const ChangePinScreen(),
                  ),
                ),
              );
            },
          ),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Document vault'),
            subtitle: Text(
              _versionLabel.isEmpty ? '…' : 'Version $_versionLabel',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
