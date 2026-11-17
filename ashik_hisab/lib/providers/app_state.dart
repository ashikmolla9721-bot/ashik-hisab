import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app state: light/dark theme plus change-counter versions used to
/// notify other tabs (IndexedStack keeps tab states alive) that the
/// database content changed and they should reload.
class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  int _ledgerVersion = 0;
  int get ledgerVersion => _ledgerVersion;

  int _historyVersion = 0;
  int get historyVersion => _historyVersion;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = (prefs.getBool('darkMode') ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', dark);
    notifyListeners();
  }

  /// Called when a transaction is added/removed (e.g. from calculator).
  void notifyLedgerChanged() {
    _ledgerVersion++;
    notifyListeners();
  }

  /// Called when a calculation is saved or history is cleared.
  void notifyHistoryChanged() {
    _historyVersion++;
    notifyListeners();
  }
}
