import 'package:darby_blackjack/features/table/table_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late TableController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(tableControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  TableState readState() => container.read(tableControllerProvider);

  group('Conteo en la mesa', () {
    test('el conteo empieza en cero y oculto', () {
      final s = readState();
      expect(s.runningCount, 0);
      expect(s.trueCount, 0);
      expect(s.showCount, isFalse);
      expect(s.countingSystemName, 'Hi-Lo');
    });

    test('toggleShowCount no altera el conteo interno', () {
      controller.deal(); // reparte y cuenta cartas visibles
      final rcAntes = readState().runningCount;

      controller.toggleShowCount();
      expect(readState().showCount, isTrue);
      expect(
        readState().runningCount,
        rcAntes,
        reason: 'mostrar no cambia el conteo',
      );

      controller.toggleShowCount();
      expect(readState().showCount, isFalse);
      expect(
        readState().runningCount,
        rcAntes,
        reason: 'ocultar no cambia el conteo',
      );
    });

    test(
      'el conteo se conserva de una ronda a la siguiente (no se reinicia)',
      () {
        controller.deal();
        if (readState().isPlayerTurn) controller.stand();
        expect(readState().isSettled, isTrue);
        final rcTrasRonda = readState().runningCount;

        controller.nextRound();
        // Al preparar la siguiente mano, el conteo acumulado se mantiene.
        expect(readState().runningCount, rcTrasRonda);
        expect(readState().isBetting, isTrue);
      },
    );
  });

  group('Modo de entrenamiento', () {
    test('en modo prueba el conteo queda oculto aunque showCount sea true', () {
      controller.toggleShowCount(); // showCount = true
      controller.setTrainingMode(TrainingMode.test);
      expect(readState().trainingMode, TrainingMode.test);
      expect(readState().showCount, isTrue);
      expect(
        readState().countVisible,
        isFalse,
        reason: 'modo prueba fuerza el conteo oculto',
      );
    });

    test('en modo libre con showCount el conteo es visible', () {
      controller.setTrainingMode(TrainingMode.free);
      controller.toggleShowCount();
      expect(readState().countVisible, isTrue);
    });

    test('checkCount compara con el running count real y actualiza stats', () {
      controller.setTrainingMode(TrainingMode.test);
      controller.deal();
      if (readState().isPlayerTurn) controller.stand();
      expect(readState().isSettled, isTrue);
      expect(readState().canCheckCount, isTrue);

      final real = readState().runningCount;
      controller.checkCount(real); // respuesta correcta
      expect(readState().checks, 1);
      expect(readState().correct, 1);
      expect(readState().lastCheck!.wasCorrect, isTrue);
      // Ya comprobado: no se puede volver a comprobar esta ronda.
      expect(readState().canCheckCount, isFalse);
    });

    test('una respuesta incorrecta no suma acierto', () {
      controller.setTrainingMode(TrainingMode.test);
      controller.deal();
      if (readState().isPlayerTurn) controller.stand();
      final real = readState().runningCount;
      controller.checkCount(real + 3); // respuesta incorrecta
      expect(readState().checks, 1);
      expect(readState().correct, 0);
      expect(readState().lastCheck!.wasCorrect, isFalse);
    });
  });

  group('Fichas', () {
    test('deal y resolución cambian el estado a settled', () {
      controller.deal();
      if (readState().isPlayerTurn) {
        controller.stand();
      }
      expect(readState().isSettled, isTrue);
    });

    test('topUp aumenta el saldo', () {
      final antes = readState().balance;
      controller.topUp(500);
      expect(readState().balance, antes + 500);
    });
  });
}
