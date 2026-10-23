---
inclusion: manual
---

# Área: Motor — Conteo de cartas

Sistema de conteo de cartas. **Dart puro** (sin Flutter ni Firebase). Es el
corazón del proyecto (requisito 3 de `requisitos.md`): practicar el conteo en
condiciones realistas.

## Archivos
- `lib/engine/counting/counting_system.dart` — interfaz `CountingSystem`
  (`name`, `valueOf(Rank)`, `isBalanced`). Permite añadir sistemas avanzados
  (KO, Omega II, etc.) sin tocar el contador.
- `lib/engine/counting/hi_lo.dart` — `HiLo`: implementación del sistema Hi-Lo.
  Valores: 2–6 → +1, 7–9 → 0, 10/J/Q/K/A → −1. Equilibrado (`isBalanced`).
- `lib/engine/counting/card_counter.dart` — `CardCounter`: acumula el running
  count de las cartas **vistas** y calcula el true count.
- `lib/engine/counting/count_trainer.dart` — `CountTrainer` + `CountCheck`:
  compara la respuesta del jugador con el running count real y acumula
  precisión, racha, mejor racha y error medio (modos de entrenamiento, req. 4 y 8).
- `lib/engine/counting/counting.dart` — barrel.

## Import
`import 'package:darby_blackjack/engine/counting/counting.dart';`

## Reglas de diseño (requisito 3)
- **Solo cuenta cartas observadas**: quien use `CardCounter` debe llamarle solo
  con cartas que el jugador ya ha visto. La hole card del crupier NO se cuenta
  hasta revelarse.
- **Running Count** = suma de `valueOf` de las cartas vistas.
- **True Count** = running count / barajas restantes (`trueCount(decksRemaining)`;
  `decksRemaining` viene del shoe y nunca es 0).
- **Independiente de la UI**: mostrar/ocultar el conteo es cosa de la interfaz;
  `CardCounter` nunca se altera por ello. `reset()` (solo al rebarajar) es lo
  único que pone el conteo a cero.

## Integración con la mesa
`TableController` (ver `ui-table.md`) tiene un `CardCounter(HiLo())`. Observa las
cartas visibles nuevas tras cada acción (índices `_observedPlayerCards` /
`_observedDealerCards` evitan recuentos); la hole card entra al resolver. Resetea
el contador solo cuando el shoe rebaraja. El botón mostrar/ocultar
(`toggleShowCount`) cambia solo la visibilidad.

## Tests
- `test/engine/counting_test.dart` — valores Hi-Lo, baraja equilibrada (suma 0),
  running count, true count (normalización por barajas), y que solo `reset`
  pone a cero.
- `test/engine/count_trainer_test.dart` — aciertos/fallos, racha y mejor racha,
  precisión, error medio, reset.
- `test/features/table_controller_test.dart` — el conteo arranca en 0 y oculto,
  `toggleShowCount` no altera el conteo, el conteo se conserva entre rondas,
  modo prueba fuerza conteo oculto, `checkCount` actualiza stats.
- Correr: `flutter test`.

## Modos de entrenamiento (ya integrados en la mesa)
- `TrainingMode.free` / `TrainingMode.test` en `TableController` (ver `ui-table.md`).
- Modo prueba: conteo oculto; al resolver la ronda el jugador introduce su
  running count y `checkCount` lo compara con el real, actualizando `CountTrainer`.

## Pendiente / siguientes pasos
- Modo guiado (explicar cómo cambia el conteo con cada carta) y práctica solo de
  conteo (sin jugar manos).
- Velocidad de conteo (tiempo de respuesta), para la Etapa 5.
- Sistemas de conteo adicionales sobre `CountingSystem` (Etapa 6).
