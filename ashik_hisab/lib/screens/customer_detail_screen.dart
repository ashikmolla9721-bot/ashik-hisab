import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../utils/helpers.dart';
import 'add_customer_screen.dart';

/// একজন কাস্টমারের বিস্তারিত খাতা: জমা/বাকি লেনদেন, মোট হিসাব।
class CustomerDetailScreen extends StatefulWidget {
  final Map<String, Object?> customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Map<String, Object?>> _txs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DbHelper.instance
        .getTxForCustomer(widget.customer['id'] as int);
    if (!mounted) return;
    setState(() {
      _txs = rows;
      _loading = false;
    });
  }

  double get _totalJama => _txs.fold<double>(
        0.0,
        (s, t) => (t['is_jama'] as int) == 1
            ? s + (t['amount'] as num).toDouble()
            : s,
      );
  double get _totalBaki => _txs.fold<double>(
        0.0,
        (s, t) => (t['is_jama'] as int) == 0
            ? s + (t['amount'] as num).toDouble()
            : s,
      );
  double get _net => _totalBaki - _totalJama;

  Future<void> _addTx(bool asBaki) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(asBaki ? 'বাকি যোগ করুন' : 'জমা যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'পরিমাণ (টাকা)', prefixText: '৳ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration:
                  const InputDecoration(labelText: 'বিবরণ (ঐচ্ছিক)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('সঠিক পরিমাণ লিখুন।')));
      }
      return;
    }
    await DbHelper.instance.insertTx({
      'customer_id': widget.customer['id'] as int,
      'is_jama': asBaki ? 0 : 1,
      'amount': amount,
      'note': noteCtrl.text.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _load();
  }

  Future<void> _deleteTx(Map<String, Object?> tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লেনদেন মুছবেন?'),
        content: const Text('এই এন্ট্রিটি স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper.instance.deleteTx(tx['id'] as int);
      await _load();
    }
  }

  Future<void> _editCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddCustomerScreen(existing: widget.customer)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteCustomer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('কাস্টমার মুছবেন?'),
        content: const Text('কাস্টমার ও তার সব লেনদেন মুছে যাবে।'),
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
      await DbHelper.instance.deleteCustomer(widget.customer['id'] as int);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final paid = _net <= 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer['name'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              tooltip: 'এডিট',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editCustomer),
          IconButton(
              tooltip: 'মুছুন',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteCustomer),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  color: paid
                      ? Colors.green.shade50
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          paid ? 'বর্তমান অবস্থা: পরিশোধিত' : 'বর্তমান বাকি',
                          style: TextStyle(
                              fontSize: 13,
                              color: paid
                                  ? Colors.green.shade900
                                  : s.onErrorContainer),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(_net.abs()),
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: paid
                                  ? Colors.green.shade900
                                  : s.onErrorContainer),
                        ),
                        if ((widget.customer['phone'] as String? ?? '')
                            .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '📞 ${toBangla(widget.customer['phone'] as String)}',
                              style: TextStyle(color: s.onSurfaceVariant),
                            ),
                          ),
                        if ((widget.customer['address'] as String? ?? '')
                            .isNotEmpty)
                          Text(
                            widget.customer['address'] as String,
                            style: TextStyle(color: s.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            minimumSize: const Size.fromHeight(48)),
                        onPressed: () => _addTx(false),
                        icon: const Icon(Icons.south),
                        label: const Text('জমা'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            minimumSize: const Size.fromHeight(48)),
                        onPressed: () => _addTx(true),
                        icon: const Icon(Icons.north),
                        label: const Text('বাকি'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _SummaryTile(
                            label: 'মোট জমা', value: money(_totalJama))),
                    Expanded(
                        child: _SummaryTile(
                            label: 'মোট বাকি', value: money(_totalBaki))),
                  ],
                ),
                const SizedBox(height: 12),
                Text('লেনদেন তালিকা (${toBangla('${_txs.length}')})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (_txs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('কোনো লেনদেন নেই।')),
                  )
                else
                  ..._txs.map((t) {
                    final isJama = t['is_jama'] as int == 1;
                    final dt = DateTime.fromMillisecondsSinceEpoch(
                        t['created_at'] as int);
                    return ListTile(
                      leading: Icon(
                        isJama ? Icons.south : Icons.north,
                        color: isJama
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        '${isJama ? 'জমা' : 'বাকি'}: ${money((t['amount'] as num).toDouble())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isJama
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: Text(
                        '${(t['note'] as String? ?? '').isEmpty ? '' : '${t['note']}\n'}${dateTimeBn(dt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteTx(t),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}
