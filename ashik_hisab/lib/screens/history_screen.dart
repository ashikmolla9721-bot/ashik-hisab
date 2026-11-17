import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../providers/app_state.dart';
import '../utils/helpers.dart';

/// হিস্ট্রি — দিন-প্রতি-দিন গ্রুপ করা হিসাবের তালিকা।
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, Object?>> _rows = [];
  bool _loading = true;
  int _seenVersion = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DbHelper.instance.getAllCalcs();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('হিস্ট্রি মুছে ফেলুন?'),
        content: const Text('সব হিসাবের ইতিহাস স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছে ফেলুন'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper.instance.clearCalcs();
      if (!mounted) return;
      context.read<AppState>().notifyHistoryChanged();
      await _load();
    }
  }

  /// Groups rows by calendar day, newest first.
  Map<String, List<Map<String, Object?>>> _groupedByDay() {
    final map = <String, List<Map<String, Object?>>>{};
    for (final r in _rows) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int);
      map.putIfAbsent(dayKey(dt), () => []).add(r);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // Reload whenever a new calculation is saved in the calculator tab.
    final version = context.watch<AppState>().historyVersion;
    if (_seenVersion != version) {
      _seenVersion = version;
      _load();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('হিস্ট্রি',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _confirmClear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('হিস্ট্রি মুছে ফেলুন'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 72,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('এখনো কোনো হিসাব নেই',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('ক্যালকুলেটরে হিসাব করলেই এখানে জমা হবে।'),
                    ],
                  ),
                )
              : _buildList(),
    );
  }

  Widget _buildList() {
    final grouped = _groupedByDay();
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: days.length,
      itemBuilder: (context, di) {
        final day = days[di];
        final items = grouped[day]!;
        final first = DateTime.parse('$day 00:00:00');
        final isToday = dayKey(DateTime.now()) == day;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(0.5),
              child: Text(
                isToday
                    ? 'আজ — ${weekdayBn(first)}, ${dateBn(first)}'
                    : '${weekdayBn(first)}, ${dateBn(first)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            ...items.map((r) {
              final dt = DateTime.fromMillisecondsSinceEpoch(
                  r['created_at'] as int);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.calculate_outlined, size: 20),
                ),
                title: Text(
                  r['expression'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('= ${r['result']}\n${timeBn(dt)}'),
                subtitleTextStyle:
                    TextStyle(color: Theme.of(context).colorScheme.outline),
                isThreeLine: true,
              );
            }),
          ],
        );
      },
    );
  }
}
