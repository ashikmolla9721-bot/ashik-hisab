import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../providers/app_state.dart';
import '../utils/calc_engine.dart';

/// ক্যালকুলেটর — English digits & operators, Bengali surrounding chrome.
/// Every "=" saves the calculation to history and offers transferring the
/// result into বাকির খাতা.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expr = '';
  String _lastResult = '';
  bool _justEvaluated = false;

  static const _ops = ['+', '-', '*', '/'];

  void _onTap(String key) {
    setState(() {
      if (key == 'C') {
        _expr = '';
        _lastResult = '';
        _justEvaluated = false;
      } else if (key == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        _justEvaluated = false;
      } else if (key == '=') {
        _evaluate();
      } else {
        if (_justEvaluated && _lastResult.isNotEmpty && !_ops.contains(key)) {
          // Starting a fresh number after "=" -> replace; with an operator -> chain.
          _expr = _ops.contains(key) ? _lastResult + key : key;
        } else {
          // Avoid two operators in a row (except minus after operator).
          if (_ops.contains(key) &&
              _expr.isNotEmpty &&
              _ops.contains(_expr[_expr.length - 1]) &&
              key != '-') {
            _expr = _expr.substring(0, _expr.length - 1);
          }
          _expr += key;
        }
        _justEvaluated = false;
      }
    });
  }

  Future<void> _evaluate() async {
    if (_expr.isEmpty) return;
    final value = CalcEngine.evaluate(_expr);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ভুল হিসাব! আবার চেষ্টা করুন।')),
      );
      return;
    }
    final resultStr = _format(value);
    final expressionStr = _expr;
    final now = DateTime.now().millisecondsSinceEpoch;
    await DbHelper.instance.insertCalc(expressionStr, resultStr, now);
    if (!mounted) return;
    context.read<AppState>().notifyHistoryChanged();
    setState(() {
      _lastResult = resultStr;
      _justEvaluated = true;
      _expr = resultStr;
    });
  }

  String _format(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    String s = v.toStringAsFixed(6);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  Future<void> _sendToLedger() async {
    if (_lastResult.isEmpty) return;
    final amount = double.tryParse(_lastResult);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই ফলাফলটি খাতায় পাঠানো যাবে না।')),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SendToLedgerSheet(amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ক্যালকুলেটর',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'খাতায় পাঠান',
            icon: const Icon(Icons.send),
            onPressed: _lastResult.isEmpty ? null : _sendToLedger,
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- Display ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            color: scheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _expr.isEmpty ? '0' : _expr,
                  style: TextStyle(
                    fontSize: 26,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _lastResult.isEmpty ? '' : '= $_lastResult',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ---------- Keypad ----------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(
                builder: (context, c) {
                  const rows = [
                    ['C', '⌫', '/', '*'],
                    ['7', '8', '9', '-'],
                    ['4', '5', '6', '+'],
                    ['1', '2', '3', '='],
                    ['0', '.', '', ''],
                  ];
                  return Column(
                    children: rows.map((row) {
                      return Expanded(
                        child: Row(
                          children: row.map((k) {
                            if (k.isEmpty) return const Spacer();
                            return Expanded(
                              child: _Key(
                                label: k,
                                onTap: () => _onTap(k),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});

  Color _bg(ColorScheme s) {
    if (label == '=') return s.primary;
    if (label == 'C') return s.errorContainer;
    if ('+-*/'.contains(label)) return s.secondaryContainer;
    return s.surfaceVariant;
  }

  Color _fg(ColorScheme s) {
    if (label == '=') return s.onPrimary;
    if (label == 'C') return s.onErrorContainer;
    return s.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: _bg(s),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _fg(s),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: pick a customer and send the result as জমা or বাকি.
class SendToLedgerSheet extends StatefulWidget {
  final double amount;
  const SendToLedgerSheet({super.key, required this.amount});

  @override
  State<SendToLedgerSheet> createState() => _SendToLedgerSheetState();
}

class _SendToLedgerSheetState extends State<SendToLedgerSheet> {
  List<Map<String, Object?>> _customers = [];
  int? _selected;
  bool _asBaki = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DbHelper.instance.getAllCustomers();
    if (!mounted) return;
    setState(() {
      _customers = rows;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_selected == null) return;
    await DbHelper.instance.insertTx({
      'customer_id': _selected,
      'is_jama': _asBaki ? 0 : 1,
      'amount': widget.amount,
      'note': 'ক্যালকুলেটর থেকে',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    if (!mounted) return;
    context.read<AppState>().notifyLedgerChanged();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('খাতায় সংরক্ষণ হয়েছে ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('খাতায় পাঠান — ৳${widget.amount}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('বাকি (ধার)')),
                    ButtonSegment(value: false, label: Text('জমা (পরিশোধ)')),
                  ],
                  selected: {_asBaki},
                  onSelectionChanged: (s) => setState(() => _asBaki = s.first),
                ),
                const SizedBox(height: 12),
                if (_customers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('কোনো কাস্টমার নেই। আগে "বাকির খাতা"-তে কাস্টমার যোগ করুন।'),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _customers.length,
                      itemBuilder: (_, i) {
                        final c = _customers[i];
                        final id = c['id'] as int;
                        return RadioListTile<int>(
                          value: id,
                          groupValue: _selected,
                          onChanged: (v) => setState(() => _selected = v),
                          title: Text(c['name'] as String),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _selected == null ? null : _save,
                  child: const Text('সংরক্ষণ করুন'),
                ),
              ],
            ),
    );
  }
}
