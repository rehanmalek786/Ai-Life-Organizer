import 'dart:convert';
import 'package:http/http.dart' as http;

class AiResult {
  final String reply;
  final Map<String, dynamic>? action;
  AiResult({required this.reply, this.action});
}

/// Talks to the Gemini API. The model is instructed to always answer in a
/// fixed JSON shape: a short reply, plus an optional "action" describing
/// something to create. The app NEVER lets the AI write to the database
/// directly - the action is only ever a proposal the user must confirm
/// (see ProposedAction in models.dart and how ai_screen.dart uses it).
class AiService {
  // Gemini's current default model as of mid-2026. If Google renames/retires
  // this model later, update this one string.
  static const String _model = 'gemini-3.6-flash';

  Future<AiResult> send({
    required String apiKey,
    required String userMessage,
    required List<Map<String, String>> history,
    required List<String> memories,
  }) async {
    if (apiKey.trim().isEmpty) {
      return AiResult(
        reply: "AI abhi set up nahi hai. Settings mein jaakar apni free Gemini API key add karein.",
      );
    }

    final now = DateTime.now().toIso8601String();
    final memoryText = memories.isEmpty ? 'None yet.' : memories.map((m) => '- $m').join('\n');

    final systemPrompt = '''
You are the assistant inside "AI Life Organizer", a personal productivity app. The user may write in English or Hinglish (Hindi+English mix). Reply in the same style/language they used, keep it short and natural.

You MUST respond with ONLY valid JSON, no markdown fences, no extra commentary, in exactly this shape:
{"reply": "short natural reply to show the user", "action": null}

or, when the user is clearly asking you to create or save something:
{"reply": "short natural reply confirming what you understood", "action": {"type": "<one of: create_task, create_reminder, create_event, create_note, create_goal, create_habit, remember>", "data": { ... }}}

Field shapes per action type:
create_task: {"title": string, "description": string, "priority": "low"|"medium"|"high", "deadline": ISO8601 string or null, "category": string}
create_reminder: {"title": string, "dateTime": ISO8601 string, "recurring": "none"|"daily"|"weekly"}
create_event: {"title": string, "startTime": ISO8601 string, "endTime": ISO8601 string or null, "location": string}
create_note: {"title": string, "body": string, "tags": [string]}
create_goal: {"title": string, "description": string, "targetDate": ISO8601 string or null}
create_habit: {"name": string, "frequency": "daily" or comma list like "mon,wed,fri"}
remember: {"content": string}

Rules:
- Only include a non-null action when the user clearly wants something created or remembered. For questions or chit-chat, action must be null.
- Resolve relative dates/times ("kal", "tomorrow", "5 baje", "next monday") into absolute ISO8601 datetimes using the current datetime given below.
- Never invent facts about the user beyond what they said or what is listed below.
- Current datetime: $now
- Known things about the user:
$memoryText
''';

    final contents = [
      ...history.map((h) => {
            'role': h['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': h['text']}
            ],
          }),
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'generationConfig': {
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode != 200) {
        return AiResult(
          reply: 'AI se connect nahi ho paaya (error ${response.statusCode}). Settings mein apni API key check karein.',
        );
      }

      final body = jsonDecode(response.body);
      final candidates = body['candidates'] as List?;
      String? text;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content != null ? content['parts'] as List? : null;
        if (parts != null && parts.isNotEmpty) {
          text = parts[0]['text'] as String?;
        }
      }

      if (text == null || text.trim().isEmpty) {
        return AiResult(reply: 'Maaf kijiye, samajh nahi paya. Dobara try karein.');
      }

      try {
        final parsed = jsonDecode(text);
        return AiResult(
          reply: parsed['reply']?.toString() ?? text,
          action: parsed['action'] as Map<String, dynamic>?,
        );
      } catch (_) {
        // Model didn't return clean JSON this time - show the raw text, no action.
        return AiResult(reply: text);
      }
    } catch (_) {
      return AiResult(reply: 'Kuch gadbad hui. Internet connection check karein aur dobara try karein.');
    }
  }

  /// Summarizes a note's body into a few short sentences. Returns a plain
  /// string (no action) - used by the "Summarize" button in Notes.
  Future<String> summarizeText({required String apiKey, required String text}) async {
    if (apiKey.trim().isEmpty) {
      return 'AI abhi set up nahi hai. Settings mein jaakar apni free Gemini API key add karein.';
    }
    if (text.trim().isEmpty) return '';

    final prompt =
        'Summarize the following note in 2-4 short sentences. Reply in the same '
        'language/style as the note (English or Hinglish). Return ONLY the '
        'summary text, no preamble, no markdown, no quotes.\n\nNote:\n$text';

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ],
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        return 'AI se connect nahi ho paaya (error ${response.statusCode}). Settings mein apni API key check karein.';
      }

      final body = jsonDecode(response.body);
      final candidates = body['candidates'] as List?;
      String? text0;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content != null ? content['parts'] as List? : null;
        if (parts != null && parts.isNotEmpty) {
          text0 = parts[0]['text'] as String?;
        }
      }

      if (text0 == null || text0.trim().isEmpty) {
        return 'Maaf kijiye, samajh nahi paya. Dobara try karein.';
      }
      return text0.trim();
    } catch (_) {
      return 'Kuch gadbad hui. Internet connection check karein aur dobara try karein.';
    }
  }

  /// Extracts candidate action-item task titles from a note's body.
  /// Returns an empty list if nothing looks like an action item, or if
  /// the request fails for any reason - callers treat empty as "none found".
  Future<List<String>> extractTasks({required String apiKey, required String text}) async {
    if (apiKey.trim().isEmpty || text.trim().isEmpty) return [];

    final prompt =
        'Read the following note and extract any clear action items / to-dos '
        'as short task titles. You MUST respond with ONLY a valid JSON array '
        'of strings, no markdown fences, no extra commentary, e.g. '
        '["Buy groceries", "Call the dentist"]. If there are no clear action '
        'items, respond with exactly [].\n\nNote:\n$text';

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ],
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      final candidates = body['candidates'] as List?;
      String? text0;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content != null ? content['parts'] as List? : null;
        if (parts != null && parts.isNotEmpty) {
          text0 = parts[0]['text'] as String?;
        }
      }
      if (text0 == null || text0.trim().isEmpty) return [];

      final parsed = jsonDecode(text0);
      if (parsed is List) {
        return parsed.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
