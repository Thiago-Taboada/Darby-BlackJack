---
inclusion: manual
---

# Área: Motor — Reglas y Juego

Reglas de mesa y flujo de una ronda de Blackjack. **Dart puro** (sin Flutter ni
Firebase). Se apoya en `engine/cards` y `engine/shoe`
(ver `engine-cards-shoe.md`). Cubre requisitos 1 y 5 de `requisitos.md`.

## Archivos
- `lib/engine/rules/table_rules.dart` — `TableRules` (inmutable) + enum `Soft17`.
  Nº barajas, penetración, S17/H17, pago BJ (num/den, p. ej. 3:2 o 6:5), doblar,
  DAS, split, maxSplitHands, peek, surrender, min/max apuesta. Presets
  `beginner` y `advanced`. `copyWith`.
- `lib/engine/rules/rules.dart` — barrel.
- `lib/engine/game/game_types.dart` — enums `PlayerAction`, `RoundPhase`,
  `HandOutcome`.
- `lib/engine/game/round.dart` — `Round`: motor mutable de una ronda.
- `lib/engine/game/game.dart` — barrel.

## Imports
- Reglas: `import 'package:darby_blackjack/engine/rules/rules.dart';`
- Juego: `import 'package:darby_blackjack/engine/game/game.dart';`

## Flujo de `Round`
`betting` → `placeBetAndDeal(bet)` (valida límites; reparto P0,P1,D0,D1) →
`playerTurn` (`hit` / `stand` / `doubleDown` / `surrender`) → `dealerTurn`
(automático) → `settled` (hay `outcome` y `netChips`).

- Reparte **primero las dos cartas del jugador y luego las dos del crupier**
  (importante para escribir guiones en tests).
- **Blackjack natural**: si el jugador tiene BJ y el crupier no → `playerBlackjack`
  (paga `blackjackPayoutMultiplier`). Con `dealerPeeks`, el BJ del crupier se
  resuelve en el reparto.
- **Crupier**: pide < 17; con 17 suave pide solo si `Soft17.hit` (H17).
- **netChips**: ganancia/pérdida neta de la mano. Win = apuesta; BJ = apuesta ×
  multiplicador; push = 0; surrender = −mitad; dealerWin = −apuesta. El `bet` ya
  está duplicado si se dobló.
- **Estado oculto (req. 13)**: `dealerHoleCardHidden` es true en `betting` y
  `playerTurn`; `dealerUpcard` solo expone la primera carta hasta entonces.

## Limitaciones actuales (MVP)
- **Split todavía no implementado** (`availableActions` no incluye `split`). El
  flujo está pensado para añadirlo sin rehacer el núcleo.
- Seguro (insurance) no implementado.

## Tests
- `test/engine/round_test.dart` — BJ 3:2 y 6:5, BJ crupier con peek, push, hit a
  bust, stand ganando, double, surrender, S17 vs H17, crupier se pasa, hole card
  oculta, validación de apuesta. Usa `Shoe.scripted([...])` para escenarios
  deterministas (orden de reparto P0,P1,D0,D1 + cartas extra).
- Correr: `flutter test`.

## Siguientes pasos del motor
- `engine/counting` (Hi-Lo: running count y true count sobre `Shoe.composition`).
- Split e insurance cuando se amplíe el flujo.
