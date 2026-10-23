import 'package:darby_blackjack/engine/cards/cards.dart';
import 'package:darby_blackjack/engine/counting/counting.dart';
import 'package:flutter_test/flutter_test.dart';

PlayingCard card(Rank rank, [Suit suit = Suit.spades]) => PlayingCard(rank, suit);

void main() {
  const hiLo = HiLo();

  group('Valores Hi-Lo', () {
    test('2-6 suman +1', () {
      for (final r in [Rank.two, Rank.three, Rank.four, Rank.five, Rank.six]) {
        expect(hiLo.valueOf(r), 1, reason: '$r debe valer +1');
      }
    });

    test('7-9 valen 0', () {
      for (final r in [Rank.seven, Rank.eight, Rank.nine]) {
        expect(hiLo.valueOf(r), 0, reason: '$r debe valer 0');
      }
    });

    test('10, J, Q, K, A valen -1', () {
      for (final r in [Rank.ten, Rank.jack, Rank.queen, Rank.king, Rank.ace]) {
        expect(hiLo.valueOf(r), -1, reason: '$r debe valer -1');
      }
    });

    test('Hi-Lo es equilibrado: una baraja completa suma 0', () {
      var sum = 0;
      for (final rank in Rank.values) {
        sum += hiLo.valueOf(rank) * 4; // 4 palos por rango
      }
      expect(sum, 0);
      expect(hiLo.isBalanced, isTrue);
    });
  });

  group('Running count', () {
    test('acumula los valores de las cartas vistas', () {
      final counter = CardCounter(hiLo);
      counter.observe(card(Rank.five)); // +1
      counter.observe(card(Rank.six)); // +1
      counter.observe(card(Rank.king)); // -1
      expect(counter.runningCount, 1);
      expect(counter.seenCount, 3);
    });

    test('observeAll cuenta una ronda completa', () {
      final counter = CardCounter(hiLo);
      counter.observeAll([
        card(Rank.two), // +1
        card(Rank.three), // +1
        card(Rank.ten), // -1
        card(Rank.seven), // 0
      ]);
      expect(counter.runningCount, 1);
      expect(counter.seenCount, 4);
    });
  });

  group('True count', () {
    test('normaliza por barajas restantes', () {
      final counter = CardCounter(hiLo);
      // Running count de +6 con 3 barajas restantes => true count 2.0
      for (var i = 0; i < 6; i++) {
        counter.observe(card(Rank.five));
      }
      expect(counter.trueCount(3.0), closeTo(2.0, 1e-9));
    });

    test('con menos barajas restantes el true count sube', () {
      final counter = CardCounter(hiLo);
      for (var i = 0; i < 4; i++) {
        counter.observe(card(Rank.four)); // +4
      }
      final tcMuchasBarajas = counter.trueCount(4.0); // 1.0
      final tcPocasBarajas = counter.trueCount(1.0); // 4.0
      expect(tcPocasBarajas, greaterThan(tcMuchasBarajas));
      expect(tcPocasBarajas, closeTo(4.0, 1e-9));
    });
  });

  group('Independencia de la UI', () {
    test('solo reset pone el conteo a cero', () {
      final counter = CardCounter(hiLo);
      counter.observe(card(Rank.five)); // +1
      counter.observe(card(Rank.four)); // +1
      expect(counter.runningCount, 2);

      // Simula "ocultar y volver a mostrar" sin tocar el conteo: no hay método
      // que lo altere salvo reset. El running count se mantiene.
      expect(counter.runningCount, 2);

      counter.reset();
      expect(counter.runningCount, 0);
      expect(counter.seenCount, 0);
    });
  });
}
