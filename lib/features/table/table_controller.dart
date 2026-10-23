import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/models/user_profile.dart';
import '../../data/profile_repository.dart';
import '../../engine/counting/counting.dart';
import '../../engine/game/game.dart';
import '../../engine/rules/rules.dart';
import '../../engine/shoe/shoe.dart';

/// Modo de entrenamiento de la mesa (requisito 4).
enum TrainingMode {
  /// Juego libre: el jugador decide si muestra u oculta el conteo.
  free,

  /// Modo prueba: el conteo se mantiene oculto y el jugador comprueba su
  /// cálculo al terminar cada ronda, midiendo su precisión.
  test,
}

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
    required this.trainingMode,
    required this.checks,
    required this.correct,
    required this.accuracy,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastCheck,
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

  /// Preferencia del jugador de mostrar el conteo. En modo prueba se ignora
  /// (el conteo permanece oculto). Ocultarlo NO altera los cálculos.
  final bool showCount;

  /// Modo de entrenamiento activo.
  final TrainingMode trainingMode;

  /// Estadísticas de precisión del conteo (modo prueba).
  final int checks;
  final int correct;
  final double accuracy;
  final int currentStreak;
  final int bestStreak;

  /// Resultado de la última comprobación de conteo, o null si no hay ninguna
  /// pendiente de mostrar.
  final CountCheck? lastCheck;

  RoundPhase get phase => round?.phase ?? RoundPhase.betting;

  bool get isBetting => round == null || phase == RoundPhase.betting;
  bool get isPlayerTurn => phase == RoundPhase.playerTurn;
  bool get isSettled => phase == RoundPhase.settled;

  /// Si la carta oculta del crupier debe ocultarse en la UI.
  bool get hideDealerHoleCard => round?.dealerHoleCardHidden ?? true;

  /// Visibilidad efectiva del conteo: en modo prueba siempre oculto.
  bool get countVisible => trainingMode == TrainingMode.free && showCount;

  /// Si procede pedir al jugador su conteo (modo prueba, ronda resuelta y aún
  /// no comprobada).
  bool get canCheckCount =>
      trainingMode == TrainingMode.test && isSettled && lastCheck == null;

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
    TrainingMode? trainingMode,
    int? checks,
    int? correct,
    double? accuracy,
    int? currentStreak,
    int? bestStreak,
    CountCheck? lastCheck,
    bool clearLastCheck = false,
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
      trainingMode: trainingMode ?? this.trainingMode,
      checks: checks ?? this.checks,
      correct: correct ?? this.correct,
      accuracy: accuracy ?? this.accuracy,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCheck: clearLastCheck ? null : (lastCheck ?? this.lastCheck),
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
  final CountTrainer _trainer = CountTrainer();

  /// Cuántas cartas del jugador y del crupier ya se han pasado al contador en la
  /// ronda actual. Garantiza que cada carta visible se cuenta una sola vez.
  int _observedPlayerCards = 0;
  int _observedDealerCards = 0;
  bool _showCount = false;
  TrainingMode _trainingMode = TrainingMode.free;

  /// Stats de precisión acumuladas entre sesiones (vienen del perfil guardado).
  int _lifetimeChecks = 0;
  int _lifetimeCorrect = 0;
  int _lifetimeBestStreak = 0;

  @override
  TableState build() {
    _shoe = Shoe(
      deckCount: _rules.deckCount,
      penetration: _rules.penetration,
      random: Random(),
    );
    // Carga el perfil guardado en segundo plano; cuando llega, aplica el saldo
    // y las preferencias. No bloquea el arranque de la mesa.
    _loadProfile();
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
      trainingMode: _trainingMode,
      checks: 0,
      correct: 0,
      accuracy: 0,
      currentStreak: 0,
      bestStreak: 0,
      lastCheck: null,
    );
  }

  /// uid del usuario actual, o null si no hay sesión o Firebase no está
  /// disponible (p. ej. en tests). Defensivo: cualquier fallo se trata como
  /// "sin sesión", de modo que la persistencia se vuelve un no-op y la mesa
  /// sigue funcionando en memoria.
  String? get _uid {
    try {
      return ref.read(authRepositoryProvider).currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Carga el perfil del usuario (si hay sesión) y aplica saldo y preferencias.
  Future<void> _loadProfile() async {
    final uid = _uid;
    // Sin sesión: se queda con los valores por defecto.
    if (uid == null) return;
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .loadOrCreate(uid);
      _showCount = profile.showCount;
      _lifetimeChecks = profile.totalChecks;
      _lifetimeCorrect = profile.correctChecks;
      _lifetimeBestStreak = profile.bestStreak;
      state = state.copyWith(
        balance: profile.balance,
        showCount: _showCount,
        bestStreak: _lifetimeBestStreak,
      );
    } catch (_) {
      // Si falla la carga (p. ej. sin red), se sigue con los valores locales.
    }
  }

  /// Guarda el estado persistente actual en Firestore (saldo, preferencia de
  /// conteo y stats de precisión acumuladas). Fire-and-forget: no bloquea la UI.
  void _persist() {
    final uid = _uid;
    if (uid == null) return;
    final profile = UserProfile(
      balance: state.balance,
      showCount: _showCount,
      totalChecks: _lifetimeChecks,
      correctChecks: _lifetimeCorrect,
      bestStreak: _lifetimeBestStreak,
    );
    // Ignora errores de red de forma silenciosa; se reintenta en el próximo cambio.
    ref.read(profileRepositoryProvider).save(uid, profile).ignore();
  }

  /// Cierra la sesión del usuario.
  Future<void> signOut() async {
    _persist();
    await ref.read(authRepositoryProvider).signOut();
  }

  TableRules get rules => _rules;

  /// Alterna mostrar/ocultar el conteo en la UI. NO toca el conteo interno:
  /// solo cambia la visibilidad (requisito 3). En modo prueba no tiene efecto
  /// visible (el conteo permanece oculto).
  void toggleShowCount() {
    _showCount = !_showCount;
    state = state.copyWith(showCount: _showCount);
    _persist();
  }

  /// Cambia el modo de entrenamiento. Al pasar a modo prueba se reinician las
  /// estadísticas de precisión para medir la sesión desde cero.
  void setTrainingMode(TrainingMode mode) {
    _trainingMode = mode;
    if (mode == TrainingMode.test) {
      _trainer.reset();
    }
    state = state.copyWith(
      trainingMode: mode,
      checks: _trainer.checks,
      correct: _trainer.correct,
      accuracy: _trainer.accuracy,
      currentStreak: _trainer.currentStreak,
      bestStreak: _trainer.bestStreak,
      clearLastCheck: true,
    );
  }

  /// Comprueba el conteo que cree el jugador contra el running count real
  /// (modo prueba). Actualiza las estadísticas de precisión y deja el resultado
  /// en `lastCheck` para que la UI dé feedback.
  void checkCount(int guess) {
    if (!state.canCheckCount) return;
    final result = _trainer.check(guess: guess, actual: _counter.runningCount);
    // Acumula las stats de precisión en las de por vida (persisten entre sesiones).
    _lifetimeChecks++;
    if (result.wasCorrect) _lifetimeCorrect++;
    if (_trainer.bestStreak > _lifetimeBestStreak) {
      _lifetimeBestStreak = _trainer.bestStreak;
    }
    state = state.copyWith(
      checks: _trainer.checks,
      correct: _trainer.correct,
      accuracy: _trainer.accuracy,
      currentStreak: _trainer.currentStreak,
      bestStreak: _lifetimeBestStreak,
      lastCheck: result,
      message: result.wasCorrect
          ? '¡Correcto! El conteo era ${result.actual}.'
          : 'Casi: dijiste ${result.guess}, era ${result.actual}.',
    );
    _persist();
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
    // Limpia el feedback de la comprobación anterior al empezar una ronda nueva.
    state = state.copyWith(clearLastCheck: true);
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
      trainingMode: _trainingMode,
      checks: _trainer.checks,
      correct: _trainer.correct,
      accuracy: _trainer.accuracy,
      currentStreak: _trainer.currentStreak,
      bestStreak: _trainer.bestStreak,
      lastCheck: null,
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
    final settled = round.phase == RoundPhase.settled;
    if (settled) {
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
    // Guarda el saldo actualizado solo al resolver la ronda (una escritura por
    // mano, para no exceder cuotas del plan gratuito).
    if (settled) _persist();
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
