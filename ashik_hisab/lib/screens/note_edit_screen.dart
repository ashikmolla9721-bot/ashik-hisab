import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../utils/helpers.dart';

/// নোট লেখা/এডিট স্ক্রিন — তৈরি ও সম্পাদনার সময় স্বয়ংক্রিয়ভাবে সংরক্ষিত হয়।
class NoteEditScreen extends StatefulWidget {
  final Map<String, Object?>? existing;
  const NoteEditScreen({super.key, this.existing});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _title = TextEditingController(
      text: widget.existing?['title'] as String? ?? '');
  late final TextEditingController _body = TextEditingController(
      text: widget.existing?['body'] as String? ?? '');

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty && body.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = DbHelper.instance;
    if (widget.existing == null) {
      await db.insertNote({
        'title': title.isEmpty ? 'শিরোনামহীন নোট' : title,
        'body': body,
        'created_at': now,
        'updated_at': now,
      });
    } else {
      await db.updateNote(widget.existing!['id'] as int, {
        'title': title.isEmpty ? 'শিরোনামহীন নোট' : title,
        'body': body,
        'updated_at': now,
      });
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'নোট এডিট' : 'নতুন নোট',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'সংরক্ষণ',
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (editing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'তৈরি: ${dateTimeBn(DateTime.fromMillisecondsSinceEpoch(widget.existing!['created_at'] as int))}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            TextField(
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'শিরোনাম',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 22, color: Colors.grey),
              ),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _body,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'এখানে লিখুন...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('সংরক্ষণ করুন'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
          ),
        ),
      ),
    );
  }
}
