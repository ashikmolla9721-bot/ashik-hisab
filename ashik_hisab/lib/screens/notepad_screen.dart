import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../utils/helpers.dart';
import 'note_edit_screen.dart';

/// নোটপ্যাড — দোকান/ব্যক্তিগত নোটের তালিকা।
class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  List<Map<String, Object?>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DbHelper.instance.getAllNotes();
    if (!mounted) return;
    setState(() {
      _notes = rows;
      _loading = false;
    });
  }

  Future<void> _openEditor({Map<String, Object?>? existing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditScreen(existing: existing)),
    );
    await _load();
  }

  Future<void> _delete(Map<String, Object?> note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নোট মুছবেন?'),
        content: const Text('এই নোটটি স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper.instance.deleteNote(note['id'] as int);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নোটপ্যাড',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.note_add),
        label: const Text('নতুন নোট'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 72,
                          color:
                              Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('এখনো কোনো নোট নেই',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('"নতুন নোট" বাটনে চাপুন।'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: _notes.length,
                  itemBuilder: (_, i) {
                    final n = _notes[i];
                    final created = DateTime.fromMillisecondsSinceEpoch(
                        n['created_at'] as int);
                    final updated = DateTime.fromMillisecondsSinceEpoch(
                        n['updated_at'] as int);
                    final wasEdited = n['updated_at'] != n['created_at'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _openEditor(existing: n),
                        title: Text(
                          n['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              n['body'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${wasEdited ? 'সম্পাদিত' : 'তৈরি'}: ${dateTimeBn(wasEdited ? updated : created)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(n),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
