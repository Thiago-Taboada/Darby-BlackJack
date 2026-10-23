import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/counting/counting.dart';
import '../../engine/game/game.dart';
import '../../engine/rules/rules.dart';
import '../../engine/shoe/shoe.dart';

/// Estado observable de la mesa que consume la UI.
///
/// Expone solo lo que el jugador debe ver. La carta oculta del crupier se
/// mantiene fuera mientras [hideDealerHoleCard] sea true (requisito 13).
class TableState {
  const TableState({
    required this.round,
    required this.balance,
    required this.bet,
    required this.cardsRemaining,
    required this.decksRemaining,
    required this.message,
    required this.countingSystemName,
    required this.runningCount,
    required this.trueCount,
    required this.showCount,
  });

  final Round? round;
  final int balance;
  final int bet;
  final int cardsRemaining;
  final double decksRemaining;
  final String message;

  /// Nombre del sistema de conteo activo (p. ej. "Hi-Lo").
  final String countingSystemName;

  /// Conteo corriente real (siempre calculado, se muestre o no).
  final int runningCount;

  /// Conteo verdadero real (siempre calculado, se muestre o no).
  final double trueCount;

  /// Si la UI debe mostrar el conteo. Ocultarlo NO altera los cálculos.
  final bool showCount;

  RoundPhase get phase => round?.phase ?? RoundPhase.betting;

  bool get isBetting => round == null || phase == RoundPhase.betting;
  bool get isPlayerTurn => phase == RoundPhase.playerTurn;
  bool get isSettled => phase == RoundPhase.settled;

  /// Si la carta oculta del crupier debe ocultarse en la UI.
  bool get hideDealerHoleCard => round?.dealerHoleCardHidden ?? true;

  TableState copyWith({
    Round? round,
    int? balance,
    int? bet,
    int? cardsRemaining,
    double? decksRemaining,
    String? message,
    String? countingSystemName,
    int? runningCount,
    double? trueCount,
    bool? showCount,
  }) {
    return TableState(
      round: round ?? this.round,
      balance: balance ?? this.balance,
      bet: bet ?? this.bet,
      cardsRemaining: cardsRemaining ?? this.cardsRemaining,
      decksRemaining: decksRemaining ?? this.decksRemaining,
      message: message ?? this.message,
      countingSystemName: countingSystemName ?? this.countingSystemName,
      runningCount: runningCount ?? this.runningCount,
      trueCount: trueCount ?? this.trueCount,
      showCount: showCount ?? this.showCount,
    );
  }
}

/// Controlador de la mesa: conecta el motor ([Round] + [Shoe]) con la UI.
///
/// Mantiene el saldo de fichas en memoria (la persistencia con Firebase llega
/// en la Etapa 4). Un único [Shoe] se reutiliza entre rondas y se rebaraja
/// cuando cruza la carta de corte, para que el conteo tenga sentido.
class TableController extends Notifier<TableState> {
  late Shoe _shoe;
  final TableRules _rules = TableRules.advanced.copyWith(
    minBet: 5,
    maxBet: 500,
  );

  final CardCounter _counter = CardCounter(const HiLo());

  /// Cuántas cartas del jugador y del crupier ya se han pasado al contador en la
  /// ronda actual. Garantiza que cada carta visible se cuenta una sola vez.
  int _observedPlayerCards = 0;
  int _observedDealerCards = 0;
  bool _showCount = false;

  @override
  TableState build() {
    _shoe = Shoe(
      deckCount: _rules.deckCount,
      penetration: _rules.penetration,
      random: Random(),
    );
    return TableState(
      round: null,
      balance: 1000,
      bet: 25,
      cardsRemaining: _shoe.cardsRemaining,
      decksRemaining: _shoe.decksRemaining,
      message: 'Haz tu apuesta y reparte.',
      countingSystemName: _counter.system.name,
      runningCount: 0,
      trueCount: 0,
      showCount: _showCount,
    );
  }

  TableRules get rules => _rules;

  /// Alterna mostrar/ocultar el conteo en la UI. NO toca el conteo interno:
  /// solo cambia la visibilidad (requisito 3).
  void toggleShowCount() {
    _showCount = !_showCount;
    state = state.copyWith(showCount: _showCount);
  }

  /// Observa las cartas visibles nuevas de la ronda y actualiza el contador.
  ///
  /// Cuenta las cartas del jugador siempre; las del crupier solo cuando dejan de
  /// estar ocultas (la hole card se cuenta al revelarse, no antes). Cada carta
  /// se pasa al contador una única vez gracias a los índices observados.
  void _observeVisibleCards(Round round) {
    final playerCards = round.playerHand.cards;
    for (var i = _observedPlayerCards; i < playerCards.length; i++) {
      _counter.observe(playerCards[i]);
    }
    _observedPlayerCards = playerCards.length;

    // Cartas visibles del crupier: todas si la hole card ya no está oculta;
    // solo la primera (upcard) mientras siga oculta.
    final dealerCards = round.dealerHand.cards;
    final visibleDealer = round.dealerHoleCardHidden
        ? (dealerCards.isEmpty ? 0 : 1)
        : dealerCards.length;
    for (var i = _observedDealerCards; i < visibleDealer; i++) {
      _counter.observe(dealerCards[i]);
    }
    _observedDealerCards = visibleDealer;
  }

  /// Ajusta la apuesta antes de repartir, respetando saldo y límites de mesa.
  void setBet(int amount) {
    if (!state.isBetting) return;
    final clamped = amount.clamp(_rules.minBet, _rules.maxBet);
    final affordable = clamped
        .clamp(_rules.minBet, max(_rules.minBet, state.balance))
        .toInt();
    state = state.copyWith(bet: affordable);
  }

  /// Rebaraja el zapato si cruzó la carta de corte en la ronda anterior.
  ///
  /// Al rebarajar, el conteo se reinicia (es el ÚNICO momento en que se resetea,
  /// nunca al ocultar el conteo en la UI).
  void _reshuffleIfNeeded() {
    if (_shoe.needsReshuffle) {
      _shoe.reshuffle();
      _counter.reset();
    }
  }

  /// Inicia una nueva ronda: valida saldo, reparte y actualiza el estado.
  void deal() {
    if (!state.isBetting) return;
    if (state.bet > state.balance) {
      state = state.copyWith(message: 'Saldo insuficiente para esa apuesta.');
      return;
    }
    _reshuffleIfNeeded();
    _observedPlayerCards = 0;
    _observedDealerCards = 0;
    final round = Round(shoe: _shoe, rules: _rules);
    round.placeBetAndDeal(state.bet);
    _syncAfterAction(round);
  }

  void hit() {
    final round = state.round;
    if (round == null || !state.isPlayerTurn) return;
    round.hit();
    _syncAfterAction(round);
  }

  void stand() {
    final round = state.round;
    if (round == null || !state.isPlayerTurn) return;
    round.stand();
    _syncAfterAction(round);
  }

  void doubleDown() {
    final round = state.round;
    if (round == null || !state.isPlayerTurn) return;
    if (!round.availableActions.contains(PlayerAction.doubleDown)) return;
    if (round.bet * 2 > state.balance) {
      state = state.copyWith(message: 'Saldo insuficiente para doblar.');
      return;
    }
    round.doubleDown();
    _syncAfterAction(round);
  }

  /// Prepara la siguiente ronda conservando el saldo y la apuesta.
  void nextRound() {
    if (!state.isSettled) return;
    state = TableState(
      round: null,
      balance: state.balance,
      bet: state.bet
          .clamp(_rules.minBet, max(_rules.minBet, state.balance))
          .toInt(),
      cardsRemaining: _shoe.cardsRemaining,
      decksRemaining: _shoe.decksRemaining,
      message: 'Haz tu apuesta y reparte.',
      countingSystemName: _counter.system.name,
      // El conteo se conserva entre rondas; solo se reinicia al rebarajar.
      runningCount: _counter.runningCount,
      trueCount: _counter.trueCount(_shoe.decksRemaining),
      showCount: _showCount,
    );
  }

  /// Recarga el saldo virtual (requisito 6).
  void topUp(int amount) {
    state = state.copyWith(balance: state.balance + amount);
  }

  /// Sincroniza el estado de la UI tras una acción del motor. Cuando la ronda
  /// se resuelve, aplica el cambio de fichas al saldo una sola vez.
  void _syncAfterAction(Round round) {
    var balance = state.balance;
    var message = _messageForPhase(round);
    if (round.phase == RoundPhase.settled) {
      balance += round.netChips;
      message = _settledMessage(round);
    }
    // Contar las cartas visibles nuevas (incluida la hole card al revelarse).
    _observeVisibleCards(round);
    state = state.copyWith(
      round: round,
      balance: balance,
      cardsRemaining: _shoe.cardsRemaining,
      decksRemaining: _shoe.decksRemaining,
      message: message,
      runningCount: _counter.runningCount,
      trueCount: _counter.trueCount(_shoe.decksRemaining),
    );
  }

  String _messageForPhase(Round round) {
    switch (round.phase) {
      case RoundPhase.playerTurn:
        return 'Tu turno: pide, plántate o dobla.';
      case RoundPhase.dealerTurn:
        return 'Turno del crupier...';
      case RoundPhase.betting:
        return 'Haz tu apuesta y reparte.';
      case RoundPhase.settled:
        return _settledMessage(round);
    }
  }

  String _settledMessage(Round round) {
    final net = round.netChips;
    switch (round.outcome!) {
      case HandOutcome.playerBlackjack:
        return '¡Blackjack! Ganas $net fichas.';
      case HandOutcome.playerWin:
        return '¡Ganas! +$net fichas.';
      case HandOutcome.dealerWin:
        return 'Gana el crupier. $net fichas.';
      case HandOutcome.push:
        return 'Empate. Recuperas tu apuesta.';
      case HandOutcome.surrendered:
        return 'Te rindes. $net fichas.';
    }
  }
}

/// Provider de la mesa.
final tableControllerProvider = NotifierProvider<TableController, TableState>(
  TableController.new,
);
