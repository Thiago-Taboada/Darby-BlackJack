import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final Round? round;
  final int balance;
  final int bet;
  final int cardsRemaining;
  final double decksRemaining;
  final String message;

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
  }) {
    return TableState(
      round: round ?? this.round,
      balance: balance ?? this.balance,
      bet: bet ?? this.bet,
      cardsRemaining: cardsRemaining ?? this.cardsRemaining,
      decksRemaining: decksRemaining ?? this.decksRemaining,
      message: message ?? this.message,
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
    );
  }

  TableRules get rules => _rules;

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
  void _reshuffleIfNeeded() {
    if (_shoe.needsReshuffle) {
      _shoe.reshuffle();
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
    state = state.copyWith(
      round: round,
      balance: balance,
      cardsRemaining: _shoe.cardsRemaining,
      decksRemaining: _shoe.decksRemaining,
      message: message,
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
