import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_controller.dart';
import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../auth/presentation/screens/change_pin_screen.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import 'recovery_backup_screen.dart';
import 'vault_maintenance_screen.dart';
import '../../../documents/presentation/screens/trash_screen.dart';

/// Module 9 – vault settings: reminders, categories, security, about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _expiryReminders = true;
  bool _privateNotifications = true;
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
    final private = await storage.getPrivateNotifications();
    PackageInfo? info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _expiryReminders = expiry;
      _privateNotifications = private;
      _lockTimeoutSeconds = timeout;
      _versionLabel = info == null
          ? ''
          : '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _setExpiry(bool value) async {
    final storage = context.read<SecureStorageService>();
    final expiry = context.read<ExpiryReminderService>();
    await storage.setExpiryRemindersEnabled(value);
    if (mounted) setState(() => _expiryReminders = value);
    try {
      await expiry.syncAll();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Preference saved. Check notification permissions and retry reminders.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickLockTimeout() async {
    final picked = await showDialog<int>(
      useRootNavigator: false,
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
    await context.read<AuthStateProvider>().setLockTimeoutSeconds(picked);
    setState(() => _lockTimeoutSeconds = picked);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final themeCtrl = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Auto'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                ),
              ],
              emptySelectionAllowed: false,
              showSelectedIcon: false,
              selected: {themeCtrl.themeMode},
              onSelectionChanged: (Set<ThemeMode> next) {
                themeCtrl.setThemeMode(next.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              '“Auto” follows your device light or dark mode.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
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
          SwitchListTile(
            secondary: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Private notifications'),
            subtitle: const Text(
              'Hide document titles. Document images are never attached.',
            ),
            value: _privateNotifications,
            onChanged: (value) async {
              final storage = context.read<SecureStorageService>();
              final reminders = context.read<ExpiryReminderService>();
              await storage.setPrivateNotifications(value);
              if (mounted) setState(() => _privateNotifications = value);
              try {
                await reminders.syncAll();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Preference saved. Some reminders could not be updated. Retry from Settings.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          const _SectionHeader('Organization'),
          ListTile(leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Vault health'), subtitle: const Text('Verify files and upgrade older encryption'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VaultMaintenanceScreen()))),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Trash'),
            subtitle: const Text(
              'Restore documents deleted in the last 30 days',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TrashScreen()),
            ),
          ),
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
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & recovery'),
            subtitle: const Text(
              'Encrypted backup for a lost or replaced device',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecoveryBackupScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-lock timeout'),
            subtitle: Text(
              _lockOptions[_lockTimeoutSeconds] ?? '$_lockTimeoutSeconds s',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickLockTimeout,
          ),
          ListTile(
            leading: const Icon(Icons.phonelink_lock_rounded),
            title: const Text('Device unlock and PIN recovery'),
            subtitle: Text(
              auth.deviceAuthAvailable
                  ? 'Your device passcode, fingerprint, or Face ID can unlock the vault independently. Use Forgot PIN on the lock screen to reset it.'
                  : 'Set up a device passcode in your device settings to enable recovery.',
            ),
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
