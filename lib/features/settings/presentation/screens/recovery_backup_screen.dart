import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/vault_backup_service.dart';
import '../../../../core/services/expiry_reminder_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../documents/presentation/providers/document_list_provider.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';

class RecoveryBackupScreen extends StatefulWidget {
  const RecoveryBackupScreen({super.key, this.documentIds});
  final Set<int>? documentIds;
  @override
  State<RecoveryBackupScreen> createState() => _RecoveryBackupScreenState();
}

class _RecoveryBackupScreenState extends State<RecoveryBackupScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _run(bool restore) async {
    if (_busy) return;
    final auth = context.read<AuthStateProvider>();
    final service = context.read<VaultBackupService>();
    final documents = context.read<DocumentListProvider>();
    final categories = context.read<CategoryListProvider>();
    final reminders = context.read<ExpiryReminderService>();
    final password = _password.text;
    if (!restore) {
      final error = VaultBackupService.validatePassword(password);
      if (error != null || password != _confirmation.text) {
        setState(() => _message = error ?? 'Recovery passwords do not match.');
        return;
      }
    } else if (password.isEmpty) {
      setState(
        () => _message = 'Enter the password used to create the backup.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      auth.requireUnlocked();
      if (restore) {
        final picked = await FilePicker.platform.pickFiles(type: FileType.any);
        if (picked == null) return;
        auth.requireUnlocked();
        final path = picked.files.single.path;
        if (path == null) {
          throw const FormatException('Could not read the selected backup.');
        }
        final file = File(path);
        if (await file.length() > VaultBackupService.maxPackageBytes) {
          throw const FormatException(
            'Backup exceeds the supported 48 MB package size.',
          );
        }
        final count = await service.restore(await file.readAsBytes(), password);
        // A scheduling/refresh problem must not turn a successful restore into
        // an apparent failure and encourage the user to restore it again.
        var warning = '';
        try {
          await documents.loadDocuments();
          await categories.loadAndEnsureDefaults();
          await reminders.syncAll();
        } catch (_) {
          warning = ' Reopen the vault to refresh lists and retry reminders.';
        }
        if (mounted) {
          setState(() => _message = 'Restored $count documents.$warning');
        }
      } else {
        final bytes = await service.create(
          password,
          documentIds: widget.documentIds,
        );
        auth.requireUnlocked();
        for (final id in widget.documentIds ?? <int>{}) {
          await documents.recordEncryptedExport(id);
        }
        final saved = await FilePicker.platform.saveFile(
          dialogTitle: 'Save encrypted recovery backup',
          fileName:
              'document-vault-${DateTime.now().toIso8601String().substring(0, 10)}.dvbackup',
          type: FileType.custom,
          allowedExtensions: ['dvbackup'],
          bytes: bytes,
        );
        if (mounted) {
          setState(
            () => _message = saved == null
                ? 'Backup saving was cancelled.'
                : 'Encrypted backup saved. Keep a copy off this device and store its password separately.',
          );
        }
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = auth.isLocked
              ? 'The vault locked. Unlock and retry the recovery operation.'
              : 'Recovery operation could not complete. Check your files and available storage, then retry.',
        );
      }
    } finally {
      if (mounted) {
        _password.clear();
        _confirmation.clear();
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.documentIds == null
                ? 'Backup & recovery'
                : 'Encrypted export',
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.documentIds == null
                      ? 'Recover after losing your device'
                      : 'Protect ${widget.documentIds!.length} selected documents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.documentIds == null
                      ? 'Save an encrypted backup to a location you can access without this phone. On a new Android or iPhone installation, create a vault PIN, then return here and restore using the backup password.'
                      : 'Export the selected current files with their titles, notes, tags, categories and dates. Previous files and activity history are excluded. The recipient can use Backup & recovery to restore this package into an empty vault.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'There is no online account or password reset service. A lost device cannot be recovered without a backup and its password. Your vault PIN and device passcode do not decrypt this backup.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Packages support up to 1,000 documents and 32 MB of file content, including retained versions in a full backup. Restore requires an empty vault and preserves your new device’s PIN and security settings.',
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enabled: !_busy,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Recovery password',
                    helperText: 'At least 12 characters for a new backup',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmation,
                  obscureText: true,
                  enabled: !_busy,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password (creating a backup only)',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _run(false),
                  icon: const Icon(Icons.save_alt_rounded),
                  label: Text(
                    widget.documentIds == null
                        ? 'Create encrypted backup'
                        : 'Save encrypted package',
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.documentIds == null)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(true),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore into empty vault'),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(liveRegion: true, child: Text(_message!)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
