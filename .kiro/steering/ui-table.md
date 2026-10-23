---
inclusion: manual
---

# Área: UI — Mesa de juego

Primera pantalla jugable: mesa de Blackjack contra el crupier. Conecta el motor
(`engine/`) con la interfaz usando Riverpod. Mobile first y responsive (se
ejecuta en Chrome para validar móvil con las DevTools). Cubre parte de los
requisitos 1, 6 y 10.

## Archivos
- `lib/features/table/table_controller.dart` — `TableController` (Notifier) +
  `TableState` + `tableControllerProvider`. Mantiene el motor (`Round`+`Shoe`),
  el saldo de fichas (en memoria por ahora) y la apuesta. Reutiliza un único
  `Shoe` entre rondas y rebaraja al cruzar la carta de corte.
- `lib/features/table/table_screen.dart` — `TableScreen` (ConsumerWidget):
  panel de info (saldo, apuesta, cartas y barajas restantes), manos del crupier
  y del jugador, mensaje y controles contextuales (apostar / jugar / siguiente).
- `lib/features/table/widgets/card_widget.dart` — `CardWidget`: dibuja una carta
  o su reverso (`faceDown`) para la hole card del crupier.
- `lib/main.dart` — `home: TableScreen()`, dentro de `ProviderScope`, tema verde.

## Flujo de UI
- **Apostar**: botones +5/+25/+100 y Reset ajustan `bet`; "Repartir" inicia la
  ronda (`controller.deal()`).
- **Turno jugador**: botones Pedir / Plantarse / Doblar, habilitados según
  `round.availableActions`.
- **Resuelto**: "Siguiente mano" (`nextRound`) conserva saldo y apuesta.
- La hole card del crupier se muestra boca abajo mientras
  `state.hideDealerHoleCard` (turno del jugador); el total visible del crupier
  solo cuenta la carta descubierta hasta que resuelve.

## Cómo ejecutar
- Web (recomendado para validar móvil): `flutter run -d chrome`, luego F12 →
  Ctrl+Shift+M para modo responsive.
- Build web: `flutter build web` (genera `build/web/`).

## Conteo Hi-Lo en la mesa (ya integrado)
- `TableController` tiene un `CardCounter(HiLo())`. Ver `engine-counting.md`.
- Panel de conteo (`_CountPanel`): muestra sistema, Running y True count. Usa
  `state.countVisible` (no `showCount` directamente).
- Botón en la AppBar (`toggleShowCount`): muestra/oculta el conteo en modo libre.
  Oculto se ve "•••"; el cálculo interno nunca se altera.
- La hole card del crupier no se cuenta hasta revelarse; el conteo se conserva
  entre rondas y solo se reinicia al rebarajar el shoe.

## Modos de entrenamiento (requisito 4)
- `TrainingMode` (free / test) en `TableController`; selector `_ModeSelector`
  (SegmentedButton) en la pantalla.
- **Modo prueba**: `countVisible` es siempre false (el botón del ojo se desactiva).
  Al resolver la ronda, `_CountCheckInput` pide el running count al jugador;
  `controller.checkCount(guess)` lo compara con el real y da feedback.
- `_TrainingStats` muestra aciertos, precisión, racha y mejor racha (solo en
  modo prueba). Datos de `CountTrainer`.

## Pendiente / notas
- Saldo y apuestas viven en memoria; la persistencia con Firebase llega en la
  Etapa 4. `topUp()` ya existe para recargar saldo.
- Sin animaciones ni sonido todavía (Etapa 3 avanzada / 10).
- El layout es scrollable (`LayoutBuilder` + `SingleChildScrollView` +
  `IntrinsicHeight`) para no desbordar en pantallas bajas.
