import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _fs = FirestoreService();
  final _notif = NotificationService();
  final _keyCtrl = TextEditingController();
  bool _keySaved = false;
  bool _obscure = true;
  bool? _exactAlarmsAllowed;

  @override
  void initState() {
    super.initState();
    _loadKey();
    _checkExactAlarms();
  }

  Future<void> _checkExactAlarms() async {
    final allowed = await _notif.canScheduleExact();
    if (mounted) setState(() => _exactAlarmsAllowed = allowed);
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

  Future<void> _exportData() async {
    final data = await _fs.exportAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your data (JSON)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(child: SelectableText(jsonStr, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonStr));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
            },
            child: const Text('Copy to clipboard'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final passwordCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This permanently deletes all your data - tasks, notes, goals, habits, reminders, events, and memories. This cannot be undone.'),
            const SizedBox(height: 16),
            TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm your password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;
      final cred = EmailAuthProvider.credential(email: user.email!, password: passwordCtrl.text);
      await user.reauthenticateWithCredential(cred);
      await _fs.deleteAllUserData();
      await user.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete account: incorrect password or network issue.')));
      }
    }
  }

  Future<void> _showUpgradeDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Create your account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final result = await context.read<AuthProvider>().upgradeGuestAccount(emailCtrl.text, passwordCtrl.text, nameCtrl.text);
                if (result == null) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } else {
                  setDialogState(() => error = result);
                }
              },
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
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
          Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_exactAlarmsAllowed == true ? Icons.check_circle : Icons.error_outline,
                          size: 18, color: _exactAlarmsAllowed == true ? AppColors.success : Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _exactAlarmsAllowed == null
                              ? 'Checking exact-alarm access...'
                              : _exactAlarmsAllowed == true
                                  ? 'Exact-time reminders are allowed'
                                  : 'Exact-time reminders are not allowed yet',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (_exactAlarmsAllowed == false) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        await _notif.requestExactAlarmAccess();
                        _checkExactAlarms();
                      },
                      child: const Text('Allow exact alarms'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _notif.sendTestNotification(),
                    icon: const Icon(Icons.notifications_active_outlined, size: 18),
                    label: const Text('Send test notification'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await _notif.scheduleReminder(
                        id: 888887,
                        title: 'Scheduled test reminder',
                        dateTime: DateTime.now().add(const Duration(seconds: 10)),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok
                              ? 'Scheduled - keep the screen off/app closed and wait 10 seconds.'
                              : 'Could not schedule at all - this points to a permission problem.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text('Schedule test reminder in 10 seconds'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'This tests actual scheduling (not an instant notification). If the instant test above works but this one never arrives after 10 seconds, your phone\'s battery settings are blocking it - see note below.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.priorityMedium.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.battery_alert_outlined, size: 18, color: AppColors.priorityMedium),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'On some phones (Xiaomi/Redmi, Oppo, Vivo, Realme especially), Android battery-saving kills scheduled reminders unless you allow it manually: Phone Settings -> Apps -> AI Life Organizer -> Battery -> set to "Unrestricted" / "No restrictions".',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (auth.isGuest) ...[
            const SizedBox(height: 28),
            Text('You are browsing as a guest', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Create an account to keep this data permanently and sign in on other devices.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showUpgradeDialog(context),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Create account'),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 28),
          Text('Danger zone', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _exportData, icon: const Icon(Icons.download), label: const Text('Export my data')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error, side: BorderSide(color: Theme.of(context).colorScheme.error)),
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete my account'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
