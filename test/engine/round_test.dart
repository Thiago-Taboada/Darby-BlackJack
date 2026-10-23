import 'package:darby_blackjack/engine/cards/cards.dart';
import 'package:darby_blackjack/engine/game/game.dart';
import 'package:darby_blackjack/engine/rules/rules.dart';
import 'package:darby_blackjack/engine/shoe/shoe.dart';
import 'package:flutter_test/flutter_test.dart';

PlayingCard c(Rank rank, [Suit suit = Suit.spades]) => PlayingCard(rank, suit);

/// El motor reparte primero las dos cartas del jugador y luego las dos del
/// crupier (P0, P1, D0, D1). Este helper arma el guion del zapato en ese orden
/// y añade las cartas extra (hits posteriores) al final.
Shoe scriptedDeal({
  required List<PlayingCard> player,
  required List<PlayingCard> dealer,
  List<PlayingCard> extra = const [],
}) {
  return Shoe.scripted([player[0], player[1], dealer[0], dealer[1], ...extra]);
}

void main() {
  const rules = TableRules(dealerPeeks: true, minBet: 1, maxBet: 500);

  group('Reparto inicial y blackjack natural', () {
    test('blackjack del jugador paga 3:2', () {
      final shoe = scriptedDeal(
        player: [c(Rank.ace), c(Rank.king)],
        dealer: [c(Rank.nine), c(Rank.seven)],
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(100);
      expect(round.phase, RoundPhase.settled);
      expect(round.outcome, HandOutcome.playerBlackjack);
      expect(round.netChips, 150); // 100 * 3/2
    });

    test('blackjack del crupier con peek: el jugador pierde', () {
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.nine)],
        dealer: [c(Rank.ace), c(Rank.king)],
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(100);
      expect(round.outcome, HandOutcome.dealerWin);
      expect(round.netChips, -100);
    });

    test('ambos con blackjack: empate', () {
      final shoe = scriptedDeal(
        player: [c(Rank.ace), c(Rank.king)],
        dealer: [c(Rank.ace), c(Rank.queen)],
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(100);
      expect(round.outcome, HandOutcome.push);
      expect(round.netChips, 0);
    });

    test('blackjack 6:5 paga menos', () {
      const rules65 = TableRules(
        blackjackPayoutNumerator: 6,
        blackjackPayoutDenominator: 5,
      );
      final shoe = scriptedDeal(
        player: [c(Rank.ace), c(Rank.king)],
        dealer: [c(Rank.nine), c(Rank.seven)],
      );
      final round = Round(shoe: shoe, rules: rules65);
      round.placeBetAndDeal(100);
      expect(round.netChips, 120); // 100 * 6/5
    });
  });

  group('Acciones del jugador', () {
    test('hit hasta pasarse: pierde', () {
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.six)],
        dealer: [c(Rank.nine), c(Rank.seven)],
        extra: [c(Rank.king)], // 10 + 6 + 10 = 26 bust
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(50);
      expect(round.phase, RoundPhase.playerTurn);
      round.hit();
      expect(round.playerHand.isBust, isTrue);
      expect(round.outcome, HandOutcome.dealerWin);
      expect(round.netChips, -50);
    });

    test('stand: gana con mano mayor', () {
      // Jugador 20, crupier 18 (9+7 => 16, pide, saca 2 => 18).
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.ten, Suit.hearts)],
        dealer: [c(Rank.nine), c(Rank.seven)],
        extra: [c(Rank.two)], // crupier pide con 16 y llega a 18
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(50);
      round.stand();
      expect(round.dealerHand.total, 18);
      expect(round.outcome, HandOutcome.playerWin);
      expect(round.netChips, 50);
    });

    test('double down: duplica apuesta, una carta y se planta', () {
      // Jugador 11 -> doubla -> saca 10 -> 21. Crupier 9+7=16, pide 2 -> 18.
      final shoe = scriptedDeal(
        player: [c(Rank.six), c(Rank.five)],
        dealer: [c(Rank.nine), c(Rank.seven)],
        extra: [
          c(Rank.ten),
          c(Rank.two),
        ], // carta del double, luego hit crupier
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(50);
      round.doubleDown();
      expect(round.bet, 100);
      expect(round.wasDoubled, isTrue);
      expect(round.playerHand.total, 21);
      expect(round.outcome, HandOutcome.playerWin);
      expect(round.netChips, 100); // gana la apuesta doblada
    });

    test('surrender: recupera la mitad', () {
      const rulesSurrender = TableRules(allowSurrender: true);
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.six)],
        dealer: [c(Rank.ten, Suit.hearts), c(Rank.seven)],
      );
      final round = Round(shoe: shoe, rules: rulesSurrender);
      round.placeBetAndDeal(100);
      expect(round.availableActions.contains(PlayerAction.surrender), isTrue);
      round.surrender();
      expect(round.outcome, HandOutcome.surrendered);
      expect(round.netChips, -50);
    });
  });

  group('Resolución del crupier (S17 / H17)', () {
    test('S17: el crupier se planta con 17 suave', () {
      // Crupier A+6 = 17 suave. Con S17 no pide. Jugador 18 gana.
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.eight)],
        dealer: [c(Rank.ace), c(Rank.six)],
      );
      const s17 = TableRules(dealerSoft17: Soft17.stand);
      final round = Round(shoe: shoe, rules: s17);
      round.placeBetAndDeal(10);
      round.stand();
      expect(round.dealerHand.total, 17);
      expect(round.outcome, HandOutcome.playerWin);
    });

    test('H17: el crupier pide con 17 suave', () {
      // Crupier A+6 = 17 suave; con H17 pide y saca 4 => 21. Jugador 18 pierde.
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.eight)],
        dealer: [c(Rank.ace), c(Rank.six)],
        extra: [c(Rank.four)],
      );
      const h17 = TableRules(dealerSoft17: Soft17.hit);
      final round = Round(shoe: shoe, rules: h17);
      round.placeBetAndDeal(10);
      round.stand();
      expect(round.dealerHand.total, 21);
      expect(round.outcome, HandOutcome.dealerWin);
    });

    test('el crupier se pasa: el jugador gana', () {
      // Crupier 10+6=16 pide y saca K => 26 bust. Jugador 19.
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.nine)],
        dealer: [c(Rank.ten, Suit.hearts), c(Rank.six)],
        extra: [c(Rank.king)],
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(10);
      round.stand();
      expect(round.dealerHand.isBust, isTrue);
      expect(round.outcome, HandOutcome.playerWin);
    });
  });

  group('Información oculta del crupier', () {
    test('durante el turno del jugador la hole card está oculta', () {
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.six)],
        dealer: [c(Rank.nine), c(Rank.seven)],
        extra: [c(Rank.two)], // crupier 16 pide y llega a 18
      );
      final round = Round(shoe: shoe, rules: rules);
      round.placeBetAndDeal(10);
      expect(round.phase, RoundPhase.playerTurn);
      expect(round.dealerHoleCardHidden, isTrue);
      expect(round.dealerUpcard, c(Rank.nine));
      round.stand();
      expect(round.dealerHoleCardHidden, isFalse);
    });
  });

  group('Validación de apuesta', () {
    test('apuesta fuera de límites lanza ArgumentError', () {
      final shoe = scriptedDeal(
        player: [c(Rank.ten), c(Rank.six)],
        dealer: [c(Rank.nine), c(Rank.seven)],
      );
      final round = Round(shoe: shoe, rules: rules);
      expect(() => round.placeBetAndDeal(0), throwsArgumentError);
      expect(() => round.placeBetAndDeal(1000), throwsArgumentError);
    });
  });
}
