import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../widgets/shared_widgets.dart';

const _vaultCategories = ['Document', 'Bill/Receipt', 'Personal', 'Study', 'Other'];

class _VaultEntry {
  final String id;
  final String title;
  final String category;
  final String content;
  final DateTime createdAt;

  _VaultEntry({required this.id, required this.title, required this.category, required this.content, required this.createdAt});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'category': category, 'content': content, 'createdAt': createdAt.toIso8601String()};
  factory _VaultEntry.fromJson(Map<String, dynamic> m) => _VaultEntry(
        id: m['id'],
        title: m['title'] ?? '',
        category: m['category'] ?? 'Other',
        content: m['content'] ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      );
}

/// Everything here stays fully on-device (never synced to the cloud),
/// encrypted via Android Keystore-backed secure storage, and gated behind
/// the phone's own biometric/PIN lock via local_auth.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  bool _unlocked = false;
  bool _checking = false;
  String? _error;
  List<_VaultEntry> _entries = [];

  Future<void> _unlock() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canCheck) {
        setState(() {
          _checking = false;
          _error = 'No screen lock is set up on this phone. Add a PIN, pattern, or fingerprint in Android Settings to use the Vault.';
        });
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock your Personal Vault',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok) {
        await _loadEntries();
        setState(() {
          _unlocked = true;
          _checking = false;
        });
      } else {
        setState(() => _checking = false);
      }
    } catch (e) {
      setState(() {
        _checking = false;
        _error = 'Could not verify your identity. Please try again.';
      });
    }
  }

  Future<void> _loadEntries() async {
    final raw = await _storage.read(key: 'vault_entries');
    if (raw == null) {
      _entries = [];
      return;
    }
    final list = jsonDecode(raw) as List;
    _entries = list.map((e) => _VaultEntry.fromJson(Map<String, dynamic>.from(e))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await _storage.write(key: 'vault_entries', value: raw);
  }

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntryForm(
        onSave: (title, category, content) async {
          setState(() {
            _entries.insert(
              0,
              _VaultEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title, category: category, content: content, createdAt: DateTime.now()),
            );
          });
          await _persist();
        },
      ),
    );
  }

  Future<void> _delete(_VaultEntry entry) async {
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Personal Vault')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Locked', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Your saved items are encrypted on this device and never leave it. Unlock with your phone\'s screen lock to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center)),
                ElevatedButton.icon(
                  onPressed: _checking ? null : _unlock,
                  icon: _checking ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.fingerprint),
                  label: Text(_checking ? 'Checking...' : 'Unlock Vault'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Vault'),
        actions: [IconButton(icon: const Icon(Icons.lock_outline), onPressed: () => setState(() => _unlocked = false))],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _openForm, child: const Icon(Icons.add)),
      body: _entries.isEmpty
          ? const EmptyState(icon: Icons.folder_special_outlined, title: 'Nothing saved yet', subtitle: 'Tap + to securely store a note, ID detail, or bill info.')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: _entries.length,
              itemBuilder: (context, i) {
                final e = _entries[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(e.title),
                    subtitle: Text('${e.category} • ${DateFormat('d MMM yyyy').format(e.createdAt)}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(e.content),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(onPressed: () => _delete(e), icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Delete')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EntryForm extends StatefulWidget {
  final Future<void> Function(String title, String category, String content) onSave;
  const _EntryForm({required this.onSave});
  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = _vaultCategories.first;
  bool _saving = false;

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(_titleCtrl.text.trim(), _category, _contentCtrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New vault entry', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _titleCtrl, label: 'Title'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _vaultCategories.map((c) => ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c))).toList(),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _contentCtrl, label: 'Details (numbers, notes, etc.)', maxLines: 5),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save securely')),
          ],
        ),
      ),
    );
  }
}

