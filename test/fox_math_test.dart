import 'package:flutter_test/flutter_test.dart';
import 'package:fox_ai/fox_math.dart';

String? ans(String q) {
  final r = FoxMath.solve(q);
  if (r == null) return null;
  return r.split('Ответ: ').last.split('\n').first;
}

void main() {
  test('выражения', () {
    expect(ans('2+2*2'), '6');
    expect(ans('сколько будет (12,5 + 7,5) × 4?'), '80');
    expect(ans('2^10'), '1024');
    expect(ans('корень из 16'), '4');
    expect(ans('10 / 4'), '2,5');
    expect(ans('7 x 8'), '56');
    expect(ans('3(2+1)'), '9');
    expect(ans('5 плюс 3 умножить на 2'), '11');
    expect(ans('sin(pi/2)'), '1');
  });

  test('проценты', () {
    expect(ans('15% от 2400'), '360');
    expect(ans('сколько 20 процентов от 50'), '10');
  });

  test('линейные уравнения', () {
    expect(ans('2x + 3 = 7'), 'x = 2');
    expect(ans('реши уравнение 5х - 10 = 0'), 'x = 2');
    expect(ans('3(x - 1) = x + 5'), 'x = 4');
  });

  test('квадратные уравнения', () {
    expect(ans('x² − 5x + 6 = 0'), 'x₁ = 2, x₂ = 3');
    expect(ans('x^2 - 4x + 4 = 0'), 'x = 2');
    expect(ans('x^2 + 1 = 0'), 'действительных корней нет.');
  });

  test('приближённое решение', () {
    final r = ans('x^3 = 27')!;
    expect(r, contains('3'));
    expect(ans('2^x = 8'), contains('x ≈ 3'));
  });

  test('обычные вопросы не трогает', () {
    expect(FoxMath.solve('Привет, как дела?'), isNull);
    expect(FoxMath.solve('Напиши 5 идей для выходных'), isNull);
    expect(FoxMath.solve('2024'), isNull);
    expect(FoxMath.solve('Что было в 1812 году?'), isNull);
  });
}
