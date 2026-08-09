import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _fs = FirestoreService();
  final _keyCtrl = TextEditingController();
  bool _keySaved = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _storage.read(key: 'gemini_api_key');
    if (key != null && mounted) {
      _keyCtrl.text = key;
      setState(() => _keySaved = true);
    }
  }

  Future<void> _saveKey() async {
    await _storage.write(key: 'gemini_api_key', value: _keyCtrl.text.trim());
    setState(() => _keySaved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key saved securely on this device.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(auth.user?.displayName ?? 'Your account'),
              subtitle: Text(auth.user?.email ?? ''),
            ),
          ),
          const SizedBox(height: 24),
          Text('AI Assistant', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'The AI Assistant uses Google Gemini. Get a free API key from Google AI Studio (aistudio.google.com) and paste it below. It is stored encrypted on this device only.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Gemini API key',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _saveKey, child: Text(_keySaved ? 'Update key' : 'Save key')),
          const SizedBox(height: 28),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: themeProvider.mode,
            onChanged: (v) => themeProvider.setMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeProvider.mode,
            onChanged: (v) => themeProvider.setMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeProvider.mode,
            onChanged: (v) => themeProvider.setMode(v!),
          ),
          const SizedBox(height: 20),
          Text('Memory', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Things you have asked the AI to remember.', style: Theme.of(context).textTheme.bodySmall),
          StreamBuilder<List<MemoryItem>>(
            stream: _fs.memoriesStream(),
            builder: (context, snap) {
              final memories = snap.data ?? [];
              if (memories.isEmpty) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nothing remembered yet.'));
              }
              return Column(
                children: memories
                    .map((m) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            title: Text(m.content),
                            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _fs.deleteMemory(m.id)),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
