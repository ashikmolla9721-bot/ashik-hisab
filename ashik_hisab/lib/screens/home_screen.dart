import 'package:flutter/material.dart';

import 'calculator_screen.dart';
import 'history_screen.dart';
import 'ledger_screen.dart';
import 'notepad_screen.dart';
import 'settings_screen.dart';

/// হোম — ব্র্যান্ডেড হেডার + পাঁচটি ট্যাবের বটম নেভিগেশন।
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    CalculatorScreen(),
    LedgerScreen(),
    NotepadScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  static const _titles = [
    'ক্যালকুলেটর',
    'বাকির খাতা',
    'নোটপ্যাড',
    'হিস্ট্রি',
    'সেটিংস',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calculate,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'আশিক হিসাব',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold),
                ),
                Text(
                  _titles[_index],
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'ক্যালকুলেটর',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'বাকির খাতা',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'নোটপ্যাড',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: 'হিস্ট্রি',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'সেটিংস',
          ),
        ],
      ),
    );
  }
}
