import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/cards/cards.dart';
import '../../engine/game/game.dart';
import 'table_controller.dart';
import 'widgets/card_widget.dart';

/// Pantalla principal de la mesa de Blackjack. Mobile first: una columna que se
/// adapta al ancho disponible. Permite jugar una mano completa contra el crupier.
class TableScreen extends ConsumerWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tableControllerProvider);
    final controller = ref.read(tableControllerProvider.notifier);
    final round = state.round;

    return Scaffold(
      backgroundColor: const Color(0xFF0B6B3A),
      appBar: AppBar(
        title: const Text('Darby Blackjack'),
        backgroundColor: const Color(0xFF094F2B),
        foregroundColor: Colors.white,
        actions: [
          // En modo prueba el conteo siempre va oculto: el botón se desactiva.
          IconButton(
            tooltip: state.trainingMode == TrainingMode.test
                ? 'Oculto en modo prueba'
                : (state.showCount ? 'Ocultar conteo' : 'Mostrar conteo'),
            icon: Icon(
              state.countVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: state.trainingMode == TrainingMode.test
                ? null
                : controller.toggleShowCount,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: controller.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Scroll si la pantalla es baja (móvil en horizontal, ventanas
                // pequeñas); usa Spacers para repartir el espacio si hay sitio.
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _InfoPanel(state: state),
                            const SizedBox(height: 8),
                            _ModeSelector(state: state, controller: controller),
                            const SizedBox(height: 8),
                            _CountPanel(state: state),
                            if (state.trainingMode == TrainingMode.test) ...[
                              const SizedBox(height: 8),
                              _TrainingStats(state: state),
                            ],
                            const SizedBox(height: 16),
                            _HandArea(
                              title: 'Crupier',
                              cards: round?.dealerHand.cards ?? const [],
                              hideSecondCard: state.hideDealerHoleCard,
                              total: _dealerVisibleTotal(state),
                            ),
                            const Spacer(),
                            _Message(message: state.message),
                            const Spacer(),
                            _HandArea(
                              title: 'Tú',
                              cards: round?.playerHand.cards ?? const [],
                              hideSecondCard: false,
                              total: round?.playerHand.cards.isEmpty ?? true
                                  ? null
                                  : round!.playerHand.total,
                            ),
                            const SizedBox(height: 16),
                            _Controls(state: state, controller: controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Total visible del crupier: durante el turno del jugador solo cuenta la
  /// carta descubierta; después, el total real.
  int? _dealerVisibleTotal(TableState state) {
    final round = state.round;
    if (round == null || round.dealerHand.cards.isEmpty) return null;
    if (state.hideDealerHoleCard) {
      return round.dealerHand.cards.first.blackjackValue;
    }
    return round.dealerHand.total;
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.state});

  final TableState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Stat(label: 'Saldo', value: '${state.balance}'),
          _Stat(label: 'Apuesta', value: '${state.bet}'),
          _Stat(label: 'Cartas', value: '${state.cardsRemaining}'),
          _Stat(
            label: 'Barajas',
            value: state.decksRemaining.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Selector de modo de entrenamiento: Libre o Prueba (requisito 4).
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.state, required this.controller});

  final TableState state;
  final TableController controller;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrainingMode>(
      style: SegmentedButton.styleFrom(
        foregroundColor: Colors.white70,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: const Color(0xFF094F2B),
      ),
      segments: const [
        ButtonSegment(
          value: TrainingMode.free,
          label: Text('Libre'),
          icon: Icon(Icons.sports_esports),
        ),
        ButtonSegment(
          value: TrainingMode.test,
          label: Text('Prueba'),
          icon: Icon(Icons.psychology),
        ),
      ],
      selected: {state.trainingMode},
      onSelectionChanged: (s) => controller.setTrainingMode(s.first),
    );
  }
}

/// Estadísticas de precisión del conteo en modo prueba (requisito 8).
class _TrainingStats extends StatelessWidget {
  const _TrainingStats({required this.state});

  final TableState state;

  @override
  Widget build(BuildContext context) {
    final pct = (state.accuracy * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CountStat(
            label: 'Aciertos',
            value: '${state.correct}/${state.checks}',
          ),
          _CountStat(label: 'Precisión', value: '$pct%'),
          _CountStat(label: 'Racha', value: '${state.currentStreak}'),
          _CountStat(label: 'Mejor', value: '${state.bestStreak}'),
        ],
      ),
    );
  }
}

/// Panel del conteo Hi-Lo. Cuando está oculto muestra "•••" para que el jugador
/// practique mentalmente; el cálculo interno sigue corriendo (requisito 3).
class _CountPanel extends StatelessWidget {
  const _CountPanel({required this.state});

  final TableState state;

  @override
  Widget build(BuildContext context) {
    final visible = state.countVisible;
    final rc = visible ? '${state.runningCount}' : '•••';
    final tc = visible ? state.trueCount.toStringAsFixed(1) : '•••';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: visible ? Colors.amber.withValues(alpha: 0.6) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            state.countingSystemName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          _CountStat(label: 'Running', value: rc),
          _CountStat(label: 'True', value: tc),
        ],
      ),
    );
  }
}

class _CountStat extends StatelessWidget {
  const _CountStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HandArea extends StatelessWidget {
  const _HandArea({
    required this.title,
    required this.cards,
    required this.hideSecondCard,
    required this.total,
  });

  final String title;
  final List<PlayingCard> cards;
  final bool hideSecondCard;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          total == null ? title : '$title — $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: cards.isEmpty
              ? const Center(
                  child: Text('—', style: TextStyle(color: Colors.white38)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: CardWidget(
                          card: cards[i],
                          faceDown: hideSecondCard && i == 1,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.controller});

  final TableState state;
  final TableController controller;

  @override
  Widget build(BuildContext context) {
    if (state.isBetting) {
      return _BettingControls(state: state, controller: controller);
    }
    if (state.isSettled) {
      // En modo prueba, antes de seguir el jugador comprueba su conteo.
      if (state.canCheckCount) {
        return _CountCheckInput(controller: controller);
      }
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: controller.nextRound,
          child: const Text('Siguiente mano'),
        ),
      );
    }
    // Turno del jugador.
    final actions = state.round?.availableActions ?? const <PlayerAction>{};
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: actions.contains(PlayerAction.hit)
                ? controller.hit
                : null,
            child: const Text('Pedir'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: actions.contains(PlayerAction.stand)
                ? controller.stand
                : null,
            child: const Text('Plantarse'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: actions.contains(PlayerAction.doubleDown)
                ? controller.doubleDown
                : null,
            child: const Text('Doblar'),
          ),
        ),
      ],
    );
  }
}

class _BettingControls extends StatelessWidget {
  const _BettingControls({required this.state, required this.controller});

  final TableState state;
  final TableController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final chip in const [5, 25, 100])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  onPressed: () => controller.setBet(state.bet + chip),
                  child: Text('+$chip'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: () => controller.setBet(controller.rules.minBet),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: controller.deal,
            child: Text('Repartir (apuesta ${state.bet})'),
          ),
        ),
      ],
    );
  }
}

/// Entrada para que el jugador introduzca su conteo (modo prueba). Permite
/// ajustar un número con +/− y confirmarlo para comprobar la precisión.
class _CountCheckInput extends StatefulWidget {
  const _CountCheckInput({required this.controller});

  final TableController controller;

  @override
  State<_CountCheckInput> createState() => _CountCheckInputState();
}

class _CountCheckInputState extends State<_CountCheckInput> {
  int _guess = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '¿Cuál es el conteo corriente?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: () => setState(() => _guess--),
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$_guess',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => setState(() => _guess++),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.controller.checkCount(_guess),
            child: const Text('Comprobar conteo'),
          ),
        ),
      ],
    );
  }
}
