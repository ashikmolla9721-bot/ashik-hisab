import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../providers/app_state.dart';
import '../utils/helpers.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

/// বাকির খাতা — সারসংক্ষেপ ড্যাশবোর্ড + কাস্টমার তালিকা।
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Map<String, Object?>> _customers = [];
  Map<int, List<double>> _totals = {};
  List<double> _grand = [0, 0, 0];
  bool _loading = true;
  int _seenVersion = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await DbHelper.instance.getAllCustomers();
    final t = await DbHelper.instance.getCustomerTotals();
    final g = await DbHelper.instance.getGrandTotals();
    if (!mounted) return;
    setState(() {
      _customers = c;
      _totals = t;
      _grand = g;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().ledgerVersion;
    if (_seenVersion != version) {
      _seenVersion = version;
      _load();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('বাকির খাতা',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('নতুন কাস্টমার'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  _DashboardCard(
                    totalBaki: _grand[1],
                    totalJama: _grand[0],
                    totalDue: _grand[2],
                    count: _customers.length,
                  ),
                  const SizedBox(height: 16),
                  if (_customers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'এখনো কোনো কাস্টমার যোগ করা হয়নি।\n"নতুন কাস্টমার" বাটনে চাপুন।',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._customers.map((c) {
                      final id = c['id'] as int;
                      final t = _totals[id] ?? [0, 0, 0];
                      final due = t[2];
                      final paid = due <= 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerDetailScreen(customer: c),
                              ),
                            );
                            await _load();
                          },
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Text(
                              (c['name'] as String).isNotEmpty
                                  ? toBangla((c['name'] as String)[0])
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'মোট জমা: ${money(t[0])}  •  মোট বাকি: ${money(t[1])}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                money(due.abs()),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: paid
                                      ? Colors.green.shade700
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                              Text(
                                paid ? 'পরিশোধিত' : 'পাওনা',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final double totalBaki;
  final double totalJama;
  final double totalDue;
  final int count;
  const _DashboardCard({
    required this.totalBaki,
    required this.totalJama,
    required this.totalDue,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: s.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('মোট বাজার বাকি / পাওনা',
                style: TextStyle(
                    fontSize: 13, color: s.onPrimaryContainer)),
            const SizedBox(height: 6),
            Text(
              money(totalDue > 0 ? totalDue : 0.0),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: s.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(label: 'মোট জমা', value: money(totalJama)),
                const SizedBox(width: 24),
                _MiniStat(label: 'মোট বাকি', value: money(totalBaki)),
                const SizedBox(width: 24),
                _MiniStat(label: 'কাস্টমার', value: toBangla('$count')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: s.onPrimaryContainer)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: s.onPrimaryContainer)),
      ],
    );
  }
}
