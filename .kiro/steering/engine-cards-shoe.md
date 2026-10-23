---
inclusion: manual
---

# Área: Motor — Cartas y Shoe

Núcleo del simulador. **Dart puro**, sin Flutter ni Firebase. Es la base sobre
la que se construye todo el juego (requisitos 1, 2 y 13 de `requisitos.md`).

## Archivos
- `lib/engine/cards/suit.dart` — `Suit`: palo (♣♦♥♠). No afecta al valor.
- `lib/engine/cards/rank.dart` — `Rank`: rango y su valor en Blackjack. El as
  guarda valor 11 (alto); el ajuste a 1 lo hace la mano.
- `lib/engine/cards/playing_card.dart` — `PlayingCard`: rango + palo, inmutable,
  igualdad por valor, `label` (p. ej. "A♠").
- `lib/engine/cards/hand.dart` — `Hand`: lista inmutable de cartas; calcula
  `total` (as flexible), `isSoft`, `isBust`, `isBlackjack`, `isPair`; `add()`
  devuelve una mano nueva.
- `lib/engine/cards/cards.dart` — barrel (`export`) de la capa de cartas.
- `lib/engine/shoe/shoe.dart` — `Shoe`: zapato multi-baraja.
- `lib/engine/shoe/shoe_lib.dart` — barrel de la capa del shoe.

## Imports
- Capa de cartas: `import 'package:darby_blackjack/engine/cards/cards.dart';`
- Shoe: `import 'package:darby_blackjack/engine/shoe/shoe_lib.dart';`
  (el barrel del shoe se llama `shoe_lib.dart` para no chocar con la clase `Shoe`).

## Decisiones clave del Shoe
- `allowedDeckCounts = [1, 2, 4, 6, 8]`; `cardsPerDeck = 52`.
- Mezcla **Fisher–Yates** con `Random` inyectable → **reproducible** con semilla
  (tests y simulaciones deterministas).
- **Sin reemplazo**: `deal()` saca la carta (de la cola de `_undealt`) y la
  registra en `_dealt`; no vuelve a salir hasta `reshuffle()`.
- **Carta de corte** por `penetration` (fracción, por defecto 0.75).
  `needsReshuffle` pasa a `true` al cruzarla; el motor del juego debe rebarajar
  al final de la ronda, no a mitad.
- `composition` → `Map<Rank,int>` de cartas restantes por rango (base para
  probabilidades y conteo verdadero).
- `decksRemaining` nunca es 0 (mínimo 0.25) para no dividir por cero en True Count.
- `deal()` con el zapato vacío lanza `StateError`.

## Estado interno vs. observable
`Shoe` conoce el orden completo de `_undealt`, pero no lo expone: solo da conteos
y composición. Cuando se añada `engine/game`, la carta oculta del crupier se
mantendrá fuera del estado observable de la UI.

## Tests
- `test/engine/hand_test.dart` — as flexible, blackjack, bust, pareja, inmutabilidad.
- `test/engine/shoe_test.dart` — nº de cartas por nº de barajas, cada carta
  aparece `deckCount` veces, sin repetición en una pasada, composición,
  `decksRemaining`, carta de corte, `reshuffle`, reproducibilidad por semilla.
- Correr: `flutter test`.

## Pendiente en esta área / siguientes pasos
- `engine/rules` (TableRules: S17/H17, DAS, pagos 3:2 vs 6:5, peek, surrender).
- `engine/game` (flujo de mano, Hit/Stand/Double/Split, crupier, resolución, pagos).
- `engine/counting` (Hi-Lo: running count y true count sobre la composición).
