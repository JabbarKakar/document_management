import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/vault_maintenance_service.dart';
import '../../../documents/presentation/providers/document_list_provider.dart';

class VaultMaintenanceScreen extends StatefulWidget {
  const VaultMaintenanceScreen({super.key});
  @override
  State<VaultMaintenanceScreen> createState() => _VaultMaintenanceScreenState();
}

class _VaultMaintenanceScreenState extends State<VaultMaintenanceScreen> {
  bool _busy = false;
  String? _status;
  Future<void> _run() async {
    final maintenance = context.read<VaultMaintenanceService>();
    final documents = context.read<DocumentListProvider>();
    setState(() { _busy = true; _status = 'Checking files…'; });
    try {
      final result = await maintenance.upgradeAndVerify(onProgress: (done, total) {
        if (mounted) setState(() => _status = 'Checked $done of $total documents');
      });
      await documents.loadDocuments();
      if (mounted) {
        setState(() => _status = result.failedIds.isEmpty
          ? 'Verified ${result.completed} documents, including previous versions. File and private-text encryption are up to date.'
          : 'Verified ${result.completed} documents. Could not upgrade document IDs: ${result.failedIds.join(', ')}. Originals were preserved. Retry or restore a recovery backup.');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Check interrupted. Completed upgrades are safe. Unlock and retry to continue.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: Scaffold(
    appBar: AppBar(title: const Text('Vault health')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Check files and upgrade protection', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      const Text('Checks current and previous files, upgrades older file encryption, and encrypts document titles, notes, tags and activity. Missing or unreadable files are reported without deleting their records.'),
      const SizedBox(height: 12),
      const Text('Keep a recovery backup first when possible. The upgrade temporarily needs space for one document and its previous files. You can retry an interrupted upgrade. Legacy plaintext files can only be opened after this upgrade.'),
      const SizedBox(height: 12),
      const Text('Category names, dates and structural metadata remain in the local database. Old database pages may retain earlier text until database compaction; this check does not securely erase flash storage.'),
      const SizedBox(height: 24),
      FilledButton(onPressed: _busy ? null : _run, child: const Text('Check and upgrade')),
      if (_busy) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
      if (_status != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_status!)),
    ]),
  ));
}
