/// Simple arithmetic engine for + - * / with correct operator precedence.
/// Accepts expressions like "12+3*4" or "10/4" (ASCII operators).
class CalcEngine {
  static const String _digits = '0123456789';
  static const Map<String, int> _prec = {'+': 1, '-': 1, '*': 2, '/': 2};

  /// Returns null on any syntax error or division by zero.
  static double? evaluate(String expr) {
    final tokens = _tokenize(expr);
    if (tokens == null || tokens.isEmpty) return null;
    final rpn = _toRpn(tokens);
    return _evalRpn(rpn);
  }

  static List<Object>? _tokenize(String expr) {
    final tokens = <Object>[];
    var i = 0;
    while (i < expr.length) {
      final ch = expr[i];
      if (ch == ' ') {
        i++;
        continue;
      }
      if (_digits.contains(ch) || ch == '.') {
        var j = i;
        while (j < expr.length && (_digits.contains(expr[j]) || expr[j] == '.')) {
          j++;
        }
        final numStr = expr.substring(i, j);
        if (numStr.split('.').length > 2) return null;
        final v = double.tryParse(numStr);
        if (v == null) return null;
        tokens.add(v);
        i = j;
      } else if (_prec.containsKey(ch)) {
        tokens.add(ch);
        i++;
      } else {
        return null;
      }
    }
    // Validate alternation: number, op, number, op, ...
    var expectNumber = true;
    for (final t in tokens) {
      if (t is double) {
        if (!expectNumber) return null;
        expectNumber = false;
      } else {
        if (expectNumber) return null;
        expectNumber = true;
      }
    }
    if (expectNumber) return null; // ends with an operator
    return tokens;
  }

  static List<Object> _toRpn(List<Object> tokens) {
    final output = <Object>[];
    final ops = <String>[];
    for (final t in tokens) {
      if (t is double) {
        output.add(t);
      } else {
        final op = t as String;
        while (ops.isNotEmpty && _prec[ops.last]! >= _prec[op]!) {
          output.add(ops.removeLast());
        }
        ops.add(op);
      }
    }
    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }
    return output;
  }

  static double? _evalRpn(List<Object> rpn) {
    final stack = <double>[];
    for (final t in rpn) {
      if (t is double) {
        stack.add(t);
      } else {
        if (stack.length < 2) return null;
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (t as String) {
          case '+':
            stack.add(a + b);
          case '-':
            stack.add(a - b);
          case '*':
            stack.add(a * b);
          case '/':
            if (b == 0) return null;
            stack.add(a / b);
        }
      }
    }
    if (stack.length != 1) return null;
    return stack.first;
  }
}
