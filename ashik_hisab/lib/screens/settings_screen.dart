import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../providers/app_state.dart';

/// সেটিংস — ব্র্যান্ডিং, ডার্ক মোড, ডাটা ম্যানেজমেন্ট ও অ্যাপ তথ্য।
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClearHistory(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('হিস্ট্রি মুছে ফেলুন?'),
        content: const Text('সব হিসাবের ইতিহাস মুছে যাবে।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছে ফেলুন')),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper.instance.clearCalcs();
      if (!context.mounted) return;
      context.read<AppState>().notifyHistoryChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('হিস্ট্রি মুছে ফেলা হয়েছে ✓')),
      );
    }
  }

  Future<void> _confirmWipeAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সব ডাটা মুছবেন?'),
        content: const Text(
            'কাস্টমার, লেনদেন, নোট ও হিস্ট্রি — সবকিছু স্থায়ীভাবে মুছে যাবে। এই কাজটি ফেরানো যাবে না।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('সব মুছুন')),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper.instance.wipeAllData();
      if (!context.mounted) return;
      final app = context.read<AppState>();
      app.notifyHistoryChanged();
      app.notifyLedgerChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সব ডাটা মুছে ফেলা হয়েছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ---------- Branding card ----------
          Card(
            elevation: 0,
            color: s.primaryContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: s.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.calculate,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'আশিক হিসাব',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: s.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'স্মার্ট ক্যালকুলেটর ও বাকির খাতা',
                    style: TextStyle(fontSize: 13, color: s.onPrimaryContainer),
                  ),
                  const SizedBox(height: 6),
                  Text('সংস্করণ ১.০.০',
                      style: TextStyle(
                          fontSize: 12, color: s.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ---------- Theme ----------
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('ডার্ক মোড'),
              subtitle: const Text('রাতের বেলায় চোখের আরামের জন্য'),
              value: app.themeMode == ThemeMode.dark,
              onChanged: (v) => app.setDarkMode(v),
            ),
          ),
          const SizedBox(height: 8),
          // ---------- Data management ----------
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_toggle_off),
                  title: const Text('হিস্ট্রি মুছে ফেলুন'),
                  subtitle: const Text('শুধু ক্যালকুলেটরের হিসাব মুছে যাবে'),
                  onTap: () => _confirmClearHistory(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: s.error),
                  title: Text('সব ডাটা মুছে ফেলুন',
                      style: TextStyle(color: s.error)),
                  subtitle: const Text(
                      'কাস্টমার, নোট, লেনদেন — সবকিছু মুছে যাবে'),
                  onTap: () => _confirmWipeAll(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ---------- About ----------
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('অ্যাপ সম্পর্কে'),
                  subtitle: Text(
                      'আশিক হিসাব — দোকানদারদের জন্য পরিপূর্ণ বাংলা হিসাব-নিকাশ অ্যাপ।\nক্যালকুলেটর, বাকির খাতা ও নোটপ্যাড একসাথে।'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('ডাটা কোথায় থাকে'),
                  subtitle: Text(
                      'সব ডাটা আপনার ফোনেই সংরক্ষিত থাকে — ইন্টারনেট লাগে না, কোনো তথ্য বাইরে যায় না।'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.code),
                  title: Text('ডেভেলপার'),
                  subtitle: Text('আশিক — Flutter দিয়ে তৈরি'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'আশিক হিসাব • Made with ❤️ in Bangladesh',
              style: TextStyle(fontSize: 12, color: s.outline),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
