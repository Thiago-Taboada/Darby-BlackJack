import 'package:darby_blackjack/engine/cards/cards.dart';
import 'package:flutter_test/flutter_test.dart';

PlayingCard card(Rank rank, [Suit suit = Suit.spades]) => PlayingCard(rank, suit);

void main() {
  group('Valor de la mano con as flexible', () {
    test('as cuenta como 11 cuando cabe', () {
      final hand = Hand([card(Rank.ace), card(Rank.six)]);
      expect(hand.total, 17);
      expect(hand.isSoft, isTrue);
    });

    test('as baja a 1 para no pasarse de 21', () {
      final hand = Hand([card(Rank.ace), card(Rank.six), card(Rank.king)]);
      expect(hand.total, 17); // 1 + 6 + 10
      expect(hand.isSoft, isFalse);
    });

    test('dos ases: uno vale 11 y otro 1', () {
      final hand = Hand([card(Rank.ace), card(Rank.ace)]);
      expect(hand.total, 12); // 11 + 1
      expect(hand.isSoft, isTrue);
    });

    test('tres ases y un ocho se ajustan correctamente', () {
      final hand = Hand([
        card(Rank.ace),
        card(Rank.ace),
        card(Rank.ace),
        card(Rank.eight),
      ]);
      // 11 + 1 + 1 + 8 = 21
      expect(hand.total, 21);
      expect(hand.isSoft, isTrue);
      expect(hand.isBlackjack, isFalse, reason: 'blackjack son solo 2 cartas');
    });
  });

  group('Detección de estados', () {
    test('blackjack natural: as + figura con dos cartas', () {
      final hand = Hand([card(Rank.ace), card(Rank.king)]);
      expect(hand.isBlackjack, isTrue);
      expect(hand.total, 21);
    });

    test('21 con tres cartas no es blackjack natural', () {
      final hand = Hand([card(Rank.seven), card(Rank.seven), card(Rank.seven)]);
      expect(hand.total, 21);
      expect(hand.isBlackjack, isFalse);
    });

    test('bust por encima de 21', () {
      final hand = Hand([card(Rank.king), card(Rank.queen), card(Rank.five)]);
      expect(hand.total, 25);
      expect(hand.isBust, isTrue);
    });

    test('pareja detectada por rango', () {
      final pair = Hand([card(Rank.eight, Suit.hearts), card(Rank.eight, Suit.spades)]);
      expect(pair.isPair, isTrue);
      final notPair = Hand([card(Rank.eight), card(Rank.nine)]);
      expect(notPair.isPair, isFalse);
    });

    test('añadir una carta no muta la mano original', () {
      final original = Hand([card(Rank.five)]);
      final next = original.add(card(Rank.six));
      expect(original.length, 1);
      expect(next.length, 2);
      expect(next.total, 11);
    });
  });
}
