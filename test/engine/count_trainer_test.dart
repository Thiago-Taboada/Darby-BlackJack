import 'package:darby_blackjack/engine/counting/counting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountTrainer', () {
    test('estado inicial vacío', () {
      final t = CountTrainer();
      expect(t.checks, 0);
      expect(t.correct, 0);
      expect(t.accuracy, 0);
      expect(t.currentStreak, 0);
      expect(t.bestStreak, 0);
      expect(t.lastCheck, isNull);
    });

    test('acierto exacto suma a correctos y racha', () {
      final t = CountTrainer();
      final r = t.check(guess: 3, actual: 3);
      expect(r.wasCorrect, isTrue);
      expect(r.error, 0);
      expect(t.correct, 1);
      expect(t.currentStreak, 1);
      expect(t.accuracy, 1.0);
    });

    test('fallo rompe la racha y acumula error', () {
      final t = CountTrainer();
      t.check(guess: 2, actual: 2); // acierto
      t.check(guess: 2, actual: 2); // acierto -> racha 2
      expect(t.currentStreak, 2);
      final fallo = t.check(guess: 5, actual: 2); // error +3
      expect(fallo.wasCorrect, isFalse);
      expect(fallo.error, 3);
      expect(t.currentStreak, 0);
      expect(t.bestStreak, 2);
    });

    test('precisión y error medio se calculan bien', () {
      final t = CountTrainer();
      t.check(guess: 1, actual: 1); // ok, err 0
      t.check(guess: 0, actual: 2); // fallo, err 2
      t.check(guess: 3, actual: 3); // ok, err 0
      expect(t.checks, 3);
      expect(t.correct, 2);
      expect(t.accuracy, closeTo(2 / 3, 1e-9));
      expect(t.meanAbsoluteError, closeTo(2 / 3, 1e-9));
    });

    test('mejor racha se conserva tras un fallo', () {
      final t = CountTrainer();
      t.check(guess: 1, actual: 1);
      t.check(guess: 1, actual: 1);
      t.check(guess: 1, actual: 1); // racha 3
      t.check(guess: 9, actual: 1); // fallo
      t.check(guess: 1, actual: 1); // racha 1
      expect(t.bestStreak, 3);
      expect(t.currentStreak, 1);
    });

    test('reset limpia todo', () {
      final t = CountTrainer();
      t.check(guess: 1, actual: 2);
      t.reset();
      expect(t.checks, 0);
      expect(t.correct, 0);
      expect(t.bestStreak, 0);
      expect(t.lastCheck, isNull);
    });
  });
}
