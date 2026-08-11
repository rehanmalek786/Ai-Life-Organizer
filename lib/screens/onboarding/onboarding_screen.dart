import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class _OnboardingQuestion {
  final String question;
  final List<String> options;
  final String memoryPrefix;
  const _OnboardingQuestion(this.question, this.options, this.memoryPrefix);
}

const _questions = [
  _OnboardingQuestion('What best describes you?', ['Student', 'Working professional', 'Freelancer', 'Homemaker'], 'The user is a'),
  _OnboardingQuestion('When do you focus best?', ['Mornings', 'Afternoons', 'Evenings', 'Late nights'], 'The user focuses best in the'),
  _OnboardingQuestion('What matters most to organize right now?', ['Work / study tasks', 'Daily habits', 'Personal life', 'Money'], 'The user most wants help organizing'),
  _OnboardingQuestion('How should reminders reach you?', ['Loud alarm', 'Gentle notification'], 'The user prefers reminders as a'),
];

/// Shown once, right after a new account is created (see main.dart). Every
/// question is skippable - answers are saved as Memory entries so the AI
/// Assistant already knows them from the very first chat.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _fs = FirestoreService();
  int _step = 0;
  bool _busy = false;

  Future<void> _answer(String option) async {
    setState(() => _busy = true);
    final q = _questions[_step];
    await _fs.addMemory('${q.memoryPrefix} $option'.toLowerCase().replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase()));
    if (_step == _questions.length - 1) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_reminder_sound', option == 'Loud alarm' ? 'alarm' : 'notification');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _next();
  }

  void _next() {
    if (_step < _questions.length - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await _fs.markOnboardingComplete();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_step];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [TextButton(onPressed: _busy ? null : _finish, child: const Text('Skip'))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                _questions.length,
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primary : theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text('Quick setup', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(q.question, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('This helps the AI Assistant understand you from the start - skip anytime.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 28),
            if (_busy)
              const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
            else
              ...q.options.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _answer(opt),
                      child: Text(opt),
                    ),
                  )),
            const Spacer(),
            Center(child: Text('${_step + 1} of ${_questions.length}', style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

