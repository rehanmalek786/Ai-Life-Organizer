import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _fs = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _query = '';

  void _openForm({NoteItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteForm(existing: existing, fs: _fs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search notes...'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NoteItem>>(
              stream: _fs.notesStream(),
              builder: (context, snap) {
                if (!snap.hasData) return const LoadingView();
                var notes = snap.data!;
                if (_query.isNotEmpty) {
                  notes = notes
                      .where((n) =>
                          n.title.toLowerCase().contains(_query) ||
                          n.body.toLowerCase().contains(_query) ||
                          n.tags.any((t) => t.toLowerCase().contains(_query)))
                      .toList();
                }
                if (notes.isEmpty) {
                  return const EmptyState(icon: Icons.sticky_note_2_outlined, title: 'No notes yet', subtitle: 'Tap + to write your first note.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final n = notes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _openForm(existing: n),
                        title: Text(n.title.isEmpty ? '(untitled)' : n.title),
                        subtitle: Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _fs.deleteNote(n.id)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteForm extends StatefulWidget {
  final NoteItem? existing;
  final FirestoreService fs;
  const _NoteForm({this.existing, required this.fs});
  @override
  State<_NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<_NoteForm> {
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final _bodyCtrl = TextEditingController(text: widget.existing?.body ?? '');
  late final _tagsCtrl = TextEditingController(text: widget.existing?.tags.join(', ') ?? '');

  void _save() {
    if (_titleCtrl.text.trim().isEmpty && _bodyCtrl.text.trim().isEmpty) return;
    final tags = _tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final note = NoteItem(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      tags: tags,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (widget.existing == null) {
      widget.fs.addNote(note);
    } else {
      widget.fs.updateNote(note);
    }
    Navigator.pop(context);
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
            Text(widget.existing == null ? 'New note' : 'Edit note', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _titleCtrl, label: 'Title'),
            const SizedBox(height: 12),
            AppTextField(controller: _bodyCtrl, label: 'Note', maxLines: 6),
            const SizedBox(height: 12),
            AppTextField(controller: _tagsCtrl, label: 'Tags (comma separated)'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
