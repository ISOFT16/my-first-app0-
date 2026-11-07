import 'dart:math' as math;

/// Встроенный решатель Fox AI: работает прямо на устройстве, без интернета.
///
/// Умеет:
/// • вычислять выражения: 2+2*2, (3,5+1)^2, корень из 16, sin(pi/6), 15%…
/// • решать уравнения с x: линейные и квадратные — точно и по шагам,
///   любые другие — приближённо (численно);
/// • считать проценты: «15% от 200».
///
/// Если запрос не похож на математику — возвращает null, и вопрос уходит в ИИ.
class FoxMath {
  static String? solve(String input) {
    try {
      final percent = _percent(input);
      if (percent != null) return percent;
      final t = _normalize(input);
      if (t.isEmpty || !RegExp(r'\d').hasMatch(t)) return null;
      if (t.contains('=')) return _equation(t);
      return _expression(t);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Подготовка текста
  // ---------------------------------------------------------------------------

  static String _normalize(String s) {
    var t = s.toLowerCase().trim();
    t = t.replaceAll('ё', 'е');
    t = t.replaceAll(
      RegExp(
        r'^(пожалуйста\s*,?\s*)?(реши(те|ть)?|вычисли(те|ть)?|посчитай(те)?|подсчитай|сосчитай|'
        r'сколько\s+будет|чему\s+равно|найди(те)?|найти|calculate|compute|solve|what\s+is)\s*'
        r'(уравнение|пример|выражение)?\s*:?\s*',
      ),
      '',
    );
    t = t.replaceAll(RegExp(r'(уравнение|пример|выражение)\s*:?'), '');
    t = t.replaceAll(RegExp(r'[?!]+'), '').trim();
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);

    const words = {
      'квадратный корень из': ' sqrt ',
      'корень квадратный из': ' sqrt ',
      'корень из': ' sqrt ',
      'умножить на': '*',
      'умножь на': '*',
      'умноженное на': '*',
      'разделить на': '/',
      'раздели на': '/',
      'поделить на': '/',
      'деленное на': '/',
      'в квадрате': '^2',
      'в кубе': '^3',
      'в степени': '^',
      'плюс': '+',
      'минус': '-',
      'синус': ' sin ',
      'косинус': ' cos ',
      'тангенс': ' tan ',
      'пи': ' pi ',
    };
    words.forEach((k, v) => t = t.replaceAll(k, v));

    t = t
        .replaceAll('×', '*')
        .replaceAll('·', '*')
        .replaceAll('∙', '*')
        .replaceAll('÷', '/')
        .replaceAll(':', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('π', ' pi ')
        .replaceAll('√', ' sqrt ')
        .replaceAll('**', '^')
        .replaceAll('х', 'x'); // русская «х» → x
    t = t.replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}');
    t = t.replaceAll(RegExp(r'=\s*$'), ''); // «2+2=»
    // «2 x 3» без знака «=» — это умножение.
    if (!t.contains('=')) {
      t = t.replaceAllMapped(RegExp(r'(\d)\s*x\s*(\d)'), (m) => '${m[1]}*${m[2]}');
    }
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ---------------------------------------------------------------------------
  // Проценты
  // ---------------------------------------------------------------------------

  static String? _percent(String s) {
    final m = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:%|процент\w*)\s*(?:от|из)\s*(\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    ).firstMatch(s);
    if (m == null) return null;
    final p = double.parse(m[1]!.replaceAll(',', '.'));
    final n = double.parse(m[2]!.replaceAll(',', '.'));
    final r = n * p / 100;
    return 'Решение:\n'
        '• ${_fmt(p)}% от ${_fmt(n)} = ${_fmt(n)} × ${_fmt(p)} / 100\n'
        '• = ${_fmt(r)}\n\n'
        'Ответ: ${_fmt(r)}';
  }

  // ---------------------------------------------------------------------------
  // Выражения
  // ---------------------------------------------------------------------------

  static String? _expression(String t) {
    if (t.contains('x')) return null; // переменная без уравнения — не наш случай
    final hasOperation = RegExp(r'[+*/^%]|\d\s*-|\)\s*-|sqrt|sin|cos|tan|ln|log|abs').hasMatch(t);
    if (!hasOperation) return null;
    final f = _Parser(t).parse();
    final v = f(0);
    if (v.isNaN) return 'Это выражение не определено (например, деление на ноль или корень из отрицательного числа).';
    if (v.isInfinite) return 'Получается бесконечность — скорее всего, деление на ноль.';
    return 'Вычисляю: ${_pretty(t)}\n\nОтвет: ${_fmt(v)}';
  }

  // ---------------------------------------------------------------------------
  // Уравнения
  // ---------------------------------------------------------------------------

  static String? _equation(String t) {
    final parts = t.split('=');
    if (parts.length != 2 || !t.contains('x')) return null;
    final left = _Parser(parts[0].trim()).parse();
    final right = _Parser(parts[1].trim()).parse();
    double f(double x) => left(x) - right(x);

    final steps = <String>['Переносим всё в левую часть: ${_pretty(parts[0].trim())} - (${_pretty(parts[1].trim())}) = 0'];

    // Пробуем подобрать многочлен не выше второй степени: a·x² + b·x + c.
    final c = f(0);
    final f1 = f(1), fm1 = f(-1);
    final a = (f1 + fm1 - 2 * c) / 2;
    final b = (f1 - fm1) / 2;
    bool fits(double x) {
      final expected = a * x * x + b * x + c;
      final actual = f(x);
      return actual.isFinite && (actual - expected).abs() <= 1e-7 * math.max(1, actual.abs());
    }

    final polynomial = c.isFinite && a.isFinite && b.isFinite && fits(2) && fits(-3) && fits(0.5) && fits(7);
    if (polynomial) {
      if (_zero(a) && _zero(b)) {
        return _zero(c)
            ? '${steps.first}\nПолучается 0 = 0.\n\nОтвет: x — любое число.'
            : '${steps.first}\nПолучается ${_fmt(c)} = 0 — это неверно.\n\nОтвет: решений нет.';
      }
      if (_zero(a)) {
        final x = -c / b;
        steps
          ..add('Приводим к виду b·x + c = 0: ${_fmt(b)}·x ${_signed(c)} = 0')
          ..add('x = ${_fmt(-c)} / ${_fmt(b)}')
          ..add('x = ${_fmt(x)}');
        return 'Решение (линейное уравнение):\n• ${steps.join('\n• ')}\n\nОтвет: x = ${_fmt(x)}';
      }
      steps.add('Получаем квадратное уравнение: ${_fmt(a)}·x² ${_signed(b)}·x ${_signed(c)} = 0');
      final d = b * b - 4 * a * c;
      steps.add('Дискриминант: D = b² − 4ac = (${_fmt(b)})² − 4·${_fmt(a)}·${_fmt(c)} = ${_fmt(d)}');
      if (d < -1e-12) {
        final re = -b / (2 * a);
        final im = math.sqrt(-d) / (2 * a).abs();
        steps.add('D < 0 — действительных корней нет');
        return 'Решение (квадратное уравнение):\n• ${steps.join('\n• ')}\n\n'
            'Ответ: действительных корней нет.\n'
            '(Комплексные корни: x = ${_fmt(re)} ± ${_fmt(im)}i)';
      }
      if (_zero(d)) {
        final x = -b / (2 * a);
        steps.add('D = 0 — один корень: x = −b / (2a) = ${_fmt(x)}');
        return 'Решение (квадратное уравнение):\n• ${steps.join('\n• ')}\n\nОтвет: x = ${_fmt(x)}';
      }
      final sq = math.sqrt(d);
      final x1 = (-b - sq) / (2 * a);
      final x2 = (-b + sq) / (2 * a);
      steps
        ..add('√D = ${_fmt(sq)}')
        ..add('x₁ = (−b − √D) / (2a) = ${_fmt(x1)}')
        ..add('x₂ = (−b + √D) / (2a) = ${_fmt(x2)}');
      return 'Решение (квадратное уравнение):\n• ${steps.join('\n• ')}\n\n'
          'Ответ: x₁ = ${_fmt(math.min(x1, x2))}, x₂ = ${_fmt(math.max(x1, x2))}';
    }

    // Любое другое уравнение — ищем корни численно.
    final roots = _numericRoots(f);
    if (roots.isEmpty) {
      return '${steps.first}\nЧисленный поиск на отрезке от −1000 до 1000 корней не нашёл.\n\n'
          'Ответ: на этом отрезке решений нет (или они не нашлись приближённо).';
    }
    return 'Решение (приближённое, численный метод):\n'
        '• ${steps.first}\n'
        '• Ищу, где значение меняет знак, и уточняю корень делением отрезка пополам\n\n'
        'Ответ: ${roots.map((r) => 'x ≈ ${_fmt(r)}').join(', ')}';
  }

  static List<double> _numericRoots(double Function(double) f) {
    final roots = <double>[];
    void add(double r) {
      if (!r.isFinite || f(r).abs() > 1e-6 * math.max(1, r.abs())) return;
      if (roots.any((e) => (e - r).abs() < 1e-6 * math.max(1, r.abs()))) return;
      roots.add(r);
    }

    void scan(double from, double to, double step) {
      var x0 = from;
      var y0 = f(x0);
      for (var x1 = from + step; x1 <= to && roots.length < 8; x1 += step) {
        final y1 = f(x1);
        if (y0.isFinite && y1.isFinite) {
          if (y0 == 0) {
            add(x0);
          } else if (y0 * y1 < 0) {
            var lo = x0, hi = x1, flo = y0;
            for (var i = 0; i < 80; i++) {
              final mid = (lo + hi) / 2;
              final fm = f(mid);
              if (!fm.isFinite) break;
              if (flo * fm <= 0) {
                hi = mid;
              } else {
                lo = mid;
                flo = fm;
              }
            }
            add((lo + hi) / 2);
          }
        }
        x0 = x1;
        y0 = y1;
      }
    }

    scan(-100, 100, 0.01);
    scan(-1000, 1000, 0.5);
    roots.sort();
    return roots;
  }

  // ---------------------------------------------------------------------------
  // Форматирование
  // ---------------------------------------------------------------------------

  static bool _zero(double v) => v.abs() < 1e-10;

  static String _signed(double v) => v < 0 ? '− ${_fmt(-v)}' : '+ ${_fmt(v)}';

  static String _fmt(double v) {
    if (v.isNaN) return 'не определено';
    if (v.isInfinite) return v > 0 ? '∞' : '−∞';
    final r = v.roundToDouble();
    if ((v - r).abs() < 1e-9 * math.max(1, v.abs()) && r.abs() < 1e15) {
      return r.toInt().toString();
    }
    if (v.abs() >= 1e15 || v.abs() < 1e-6) return v.toStringAsExponential(6);
    var s = v.toStringAsFixed(6);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  static String _pretty(String t) => t
      .replaceAll('*', '·')
      .replaceAll('sqrt', '√')
      .replaceAll('pi', 'π')
      .replaceAll('.', ',');
}

// -----------------------------------------------------------------------------
// Разбор выражений (рекурсивный спуск). Результат — функция от x.
// -----------------------------------------------------------------------------

typedef _Fn = double Function(double x);

class _Parser {
  _Parser(String text) : _tokens = _tokenize(text);

  final List<String> _tokens;
  int _pos = 0;

  static const _functions = {'sqrt', 'sin', 'cos', 'tan', 'ln', 'log', 'abs'};
  static const _constants = {'pi', 'e', 'x'};

  static List<String> _tokenize(String s) {
    final tokens = <String>[];
    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (ch == ' ') {
        i++;
      } else if (RegExp(r'[0-9.]').hasMatch(ch)) {
        final m = RegExp(r'\d*\.?\d+(e[+-]?\d+)?|\d+\.?').matchAsPrefix(s, i)!;
        if (m.group(0)!.split('.').length > 2) throw const FormatException('число');
        tokens.add(m.group(0)!);
        i = m.end;
      } else if (RegExp(r'[a-z]').hasMatch(ch)) {
        var j = i;
        while (j < s.length && RegExp(r'[a-z]').hasMatch(s[j])) {
          j++;
        }
        var word = s.substring(i, j);
        // Разбиваем слипшиеся имена: «sqrtx», «xpi», «pix»…
        while (word.isNotEmpty) {
          final name = [..._functions, ..._constants]
              .where(word.startsWith)
              .fold<String?>(null, (best, n) => best == null || n.length > best.length ? n : best);
          if (name == null) throw FormatException('неизвестное слово: $word');
          tokens.add(name);
          word = word.substring(name.length);
        }
        i = j;
      } else if ('+-*/^()%'.contains(ch)) {
        tokens.add(ch);
        i++;
      } else {
        throw FormatException('символ $ch');
      }
    }
    return tokens;
  }

  String? get _peek => _pos < _tokens.length ? _tokens[_pos] : null;
  String _next() => _tokens[_pos++];

  _Fn parse() {
    if (_tokens.isEmpty) throw const FormatException('пусто');
    final f = _expr();
    if (_pos != _tokens.length) throw const FormatException('лишние символы');
    return f;
  }

  _Fn _expr() {
    var left = _term();
    while (_peek == '+' || _peek == '-') {
      final op = _next();
      final l = left, r = _term();
      left = op == '+' ? (x) => l(x) + r(x) : (x) => l(x) - r(x);
    }
    return left;
  }

  bool get _startsFactor {
    final p = _peek;
    if (p == null) return false;
    return p == '(' || RegExp(r'^[0-9.]').hasMatch(p) || _functions.contains(p) || _constants.contains(p);
  }

  _Fn _term() {
    var left = _unary();
    while (true) {
      if (_peek == '*' || _peek == '/') {
        final op = _next();
        final l = left, r = _unary();
        left = op == '*' ? (x) => l(x) * r(x) : (x) => l(x) / r(x);
      } else if (_startsFactor) {
        // Неявное умножение: 2x, 3(x+1), (x+1)(x-1).
        final l = left, r = _power();
        left = (x) => l(x) * r(x);
      } else {
        return left;
      }
    }
  }

  _Fn _unary() {
    if (_peek == '-') {
      _next();
      final f = _unary();
      return (x) => -f(x);
    }
    if (_peek == '+') {
      _next();
      return _unary();
    }
    return _power();
  }

  _Fn _power() {
    final base = _postfix();
    if (_peek == '^') {
      _next();
      final exp = _unary();
      return (x) => math.pow(base(x), exp(x)).toDouble();
    }
    return base;
  }

  _Fn _postfix() {
    var f = _primary();
    while (_peek == '%') {
      _next();
      final g = f;
      f = (x) => g(x) / 100;
    }
    return f;
  }

  _Fn _primary() {
    final t = _peek;
    if (t == null) throw const FormatException('неожиданный конец');
    if (t == '(') {
      _next();
      final f = _expr();
      if (_peek != ')') throw const FormatException('нет скобки');
      _next();
      return f;
    }
    if (RegExp(r'^[0-9.]').hasMatch(t)) {
      _next();
      final v = double.parse(t);
      return (_) => v;
    }
    if (t == 'x') {
      _next();
      return (x) => x;
    }
    if (t == 'pi') {
      _next();
      return (_) => math.pi;
    }
    if (t == 'e') {
      _next();
      return (_) => math.e;
    }
    if (_functions.contains(t)) {
      _next();
      final arg = _power();
      return switch (t) {
        'sqrt' => (x) => math.sqrt(arg(x)),
        'sin' => (x) => math.sin(arg(x)),
        'cos' => (x) => math.cos(arg(x)),
        'tan' => (x) => math.tan(arg(x)),
        'ln' => (x) => math.log(arg(x)),
        'log' => (x) => math.log(arg(x)) / math.ln10,
        _ => (x) => arg(x).abs(),
      };
    }
    throw FormatException('неожиданный символ $t');
  }
}
