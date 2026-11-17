import 'package:intl/intl.dart';

const String _enDigits = '0123456789';
const List<String> _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// ASCII digit → Bengali digit. The calculator stays in English digits;
/// everything else in the app displays Bengali numerals.
String toBangla(String s) {
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final i = _enDigits.indexOf(ch);
    buf.write(i >= 0 ? _bnDigits[i] : ch);
  }
  return buf.toString();
}

/// Formats money with taka sign and Bengali digits, e.g. ৳১২৩৪.৫০
String money(double v) {
  final neg = v < 0;
  final abs = v.abs();
  final s = abs == abs.roundToDouble()
      ? abs.toStringAsFixed(0)
      : abs.toStringAsFixed(2);
  return '${neg ? '-' : ''}৳${toBangla(s)}';
}

/// e.g. ১৭ নভেম্বর ২০২৬
String dateBn(DateTime dt) =>
    toBangla(DateFormat('d MMMM yyyy', 'bn').format(dt));

/// e.g. ০৯:৩০ PM
String timeBn(DateTime dt) => toBangla(DateFormat('hh:mm a', 'bn').format(dt));

/// e.g. ১৭ নভেম্বর ২০২৬, ০৯:৩০ PM
String dateTimeBn(DateTime dt) => '${dateBn(dt)}, ${timeBn(dt)}';

/// e.g. মঙ্গলবার
String weekdayBn(DateTime dt) => DateFormat('EEEE', 'bn').format(dt);

/// Stable grouping key: 2026-11-17
String dayKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
