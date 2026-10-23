import 'dart:math';

import 'package:darby_blackjack/engine/cards/cards.dart';
import 'package:darby_blackjack/engine/shoe/shoe_lib.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Construcción del zapato', () {
    test('un zapato de N barajas tiene N*52 cartas', () {
      for (final decks in Shoe.allowedDeckCounts) {
        final shoe = Shoe(deckCount: decks, random: Random(1));
        expect(shoe.totalCards, decks * 52);
        expect(shoe.cardsRemaining, decks * 52);
        expect(shoe.cardsDealt, 0);
      }
    });

    test('cada carta física aparece deckCount veces (52 cartas reales por baraja)', () {
      const decks = 6;
      final shoe = Shoe(deckCount: decks, random: Random(1));
      final counts = <String, int>{};
      while (shoe.cardsRemaining > 0) {
        final c = shoe.deal();
        counts.update(c.label, (v) => v + 1, ifAbsent: () => 1);
      }
      // 52 cartas distintas, cada una repetida exactamente `decks` veces.
      expect(counts.length, 52);
      expect(counts.values.every((v) => v == decks), isTrue,
          reason: 'ninguna carta debe salir más o menos de $decks veces');
    });
  });

  group('Reparto sin reemplazo', () {
    test('repartir reduce las restantes y aumenta las repartidas', () {
      final shoe = Shoe(deckCount: 1, random: Random(1));
      shoe.deal();
      expect(shoe.cardsRemaining, 51);
      expect(shoe.cardsDealt, 1);
    });

    test('no se reparte ninguna carta repetida ni inexistente en una pasada', () {
      final shoe = Shoe(deckCount: 1, random: Random(7));
      final seen = <PlayingCard>[];
      while (shoe.cardsRemaining > 0) {
        seen.add(shoe.deal());
      }
      // En una baraja única no debe repetirse ninguna de las 52 cartas.
      expect(seen.toSet().length, 52);
      expect(seen.length, 52);
    });

    test('repartir con el zapato vacío lanza StateError', () {
      final shoe = Shoe(deckCount: 1, random: Random(1));
      for (var i = 0; i < 52; i++) {
        shoe.deal();
      }
      expect(shoe.deal, throwsStateError);
    });
  });

  group('Composición y barajas restantes', () {
    test('la composición refleja las cartas retiradas', () {
      final shoe = Shoe(deckCount: 1, random: Random(1));
      final totalInicial =
          shoe.composition.values.fold<int>(0, (a, b) => a + b);
      expect(totalInicial, 52);

      // Reparte media baraja y comprueba que la composición baja en consecuencia.
      for (var i = 0; i < 26; i++) {
        shoe.deal();
      }
      final totalTrasReparto =
          shoe.composition.values.fold<int>(0, (a, b) => a + b);
      expect(totalTrasReparto, 26);
    });

    test('decksRemaining decrece y nunca llega a cero', () {
      final shoe = Shoe(deckCount: 2, random: Random(1));
      expect(shoe.decksRemaining, closeTo(2.0, 1e-9));
      while (shoe.cardsRemaining > 0) {
        shoe.deal();
      }
      expect(shoe.decksRemaining, greaterThanOrEqualTo(0.25));
    });
  });

  group('Carta de corte y rebarajado', () {
    test('needsReshuffle se activa al cruzar la penetración', () {
      final shoe = Shoe(deckCount: 1, penetration: 0.5, random: Random(1));
      expect(shoe.needsReshuffle, isFalse);
      // Reparte justo hasta la carta de corte (50% de 52 = 26).
      for (var i = 0; i < 26; i++) {
        shoe.deal();
      }
      expect(shoe.needsReshuffle, isTrue);
    });

    test('reshuffle restaura todas las cartas y limpia las repartidas', () {
      final shoe = Shoe(deckCount: 1, random: Random(1));
      for (var i = 0; i < 20; i++) {
        shoe.deal();
      }
      shoe.reshuffle();
      expect(shoe.cardsRemaining, 52);
      expect(shoe.cardsDealt, 0);
      expect(shoe.needsReshuffle, isFalse);
    });
  });

  group('Reproducibilidad', () {
    test('misma semilla produce el mismo orden de reparto', () {
      final a = Shoe(deckCount: 2, random: Random(42));
      final b = Shoe(deckCount: 2, random: Random(42));
      final ordenA = [for (var i = 0; i < 20; i++) a.deal().label];
      final ordenB = [for (var i = 0; i < 20; i++) b.deal().label];
      expect(ordenA, ordenB);
    });

    test('semillas distintas producen órdenes distintos', () {
      final a = Shoe(deckCount: 2, random: Random(1));
      final b = Shoe(deckCount: 2, random: Random(2));
      final ordenA = [for (var i = 0; i < 20; i++) a.deal().label];
      final ordenB = [for (var i = 0; i < 20; i++) b.deal().label];
      expect(ordenA, isNot(ordenB));
    });
  });
}
