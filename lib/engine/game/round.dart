import '../cards/cards.dart';
import '../rules/table_rules.dart';
import '../shoe/shoe.dart';
import 'game_types.dart';

/// Motor de una ronda de Blackjack: jugador contra crupier.
///
/// Es un objeto de estado mutable que conduce una ronda de principio a fin.
/// Reparte desde un [Shoe] (sin reemplazo) y aplica las [TableRules].
///
/// Diseño pensado para el MVP: una sola mano del jugador (sin split todavía),
/// con Hit, Stand, Double y Surrender. La resolución del crupier y los pagos son
/// correctos y testeables. La estructura permite añadir split más adelante sin
/// rehacer el flujo (apostar → turno jugador → turno crupier → resolución).
///
/// ## Estado interno vs. observable (requisito 13)
/// El crupier recibe dos cartas; la segunda es la **carta oculta** (hole card).
/// Mientras dura el turno del jugador, [dealerUpcard] solo expone la primera.
/// La mano completa del crupier no debe mostrarse hasta [RoundPhase.dealerTurn].
class Round {
  Round({required this.shoe, required this.rules});

  final Shoe shoe;
  final TableRules rules;

  RoundPhase _phase = RoundPhase.betting;
  RoundPhase get phase => _phase;

  Hand _player = const Hand.empty();
  Hand _dealer = const Hand.empty();

  int _bet = 0;
  bool _doubled = false;
  HandOutcome? _outcome;

  /// Mano del jugador.
  Hand get playerHand => _player;

  /// Apuesta actual de la mano.
  int get bet => _bet;

  /// Resultado de la ronda, disponible cuando [phase] es [RoundPhase.settled].
  HandOutcome? get outcome => _outcome;

  /// Carta visible del crupier (la primera). Es la única información del crupier
  /// observable durante el turno del jugador.
  PlayingCard? get dealerUpcard => _dealer.cards.isEmpty ? null : _dealer.cards.first;

  /// Mano completa del crupier. Solo tiene sentido mostrarla una vez que el
  /// turno pasa al crupier o la ronda está resuelta.
  Hand get dealerHand => _dealer;

  /// Indica si la carta oculta del crupier debe permanecer oculta a la UI.
  bool get dealerHoleCardHidden =>
      _phase == RoundPhase.playerTurn || _phase == RoundPhase.betting;

  /// Reparto inicial: dos cartas al jugador y dos al crupier.
  ///
  /// Valida la apuesta contra los límites de la mesa. Si el crupier comprueba
  /// blackjack ([TableRules.dealerPeeks]) y lo tiene, la ronda se resuelve de
  /// inmediato. También se resuelve si el jugador tiene blackjack natural.
  void placeBetAndDeal(int bet) {
    if (_phase != RoundPhase.betting) {
      throw StateError('La apuesta solo se hace al inicio de la ronda.');
    }
    if (bet < rules.minBet || bet > rules.maxBet) {
      throw ArgumentError(
          'La apuesta $bet está fuera de los límites [${rules.minBet}, ${rules.maxBet}].');
    }
    _bet = bet;
    _player = Hand([shoe.deal(), shoe.deal()]);
    _dealer = Hand([shoe.deal(), shoe.deal()]);

    final playerBJ = _player.isBlackjack;
    final dealerBJ = _dealer.isBlackjack;

    // Con peek activado, el crupier comprueba su blackjack antes del turno.
    if (rules.dealerPeeks && dealerBJ) {
      _phase = RoundPhase.settled;
      _outcome = playerBJ ? HandOutcome.push : HandOutcome.dealerWin;
      return;
    }
    if (playerBJ) {
      // El jugador tiene blackjack; si el crupier no (ya comprobado o sin peek
      // y resultará abajo), se resuelve. Si el crupier también lo tuviera sin
      // peek, se maneja en la resolución del crupier.
      if (!dealerBJ) {
        _phase = RoundPhase.settled;
        _outcome = HandOutcome.playerBlackjack;
        return;
      }
      _phase = RoundPhase.settled;
      _outcome = HandOutcome.push;
      return;
    }
    _phase = RoundPhase.playerTurn;
  }

  /// Acciones disponibles para el jugador en el estado actual.
  Set<PlayerAction> get availableActions {
    if (_phase != RoundPhase.playerTurn) return const {};
    final actions = <PlayerAction>{PlayerAction.hit, PlayerAction.stand};
    final isInitialTwoCards = _player.length == 2;
    if (isInitialTwoCards && rules.allowDouble) {
      actions.add(PlayerAction.doubleDown);
    }
    if (isInitialTwoCards && rules.allowSurrender) {
      actions.add(PlayerAction.surrender);
    }
    return actions;
  }

  /// El jugador pide una carta. Si se pasa, termina su turno y pierde.
  void hit() {
    _requirePlayerTurn();
    _player = _player.add(shoe.deal());
    if (_player.isBust) {
      _phase = RoundPhase.settled;
      _outcome = HandOutcome.dealerWin;
    }
  }

  /// El jugador se planta; pasa el turno al crupier y se resuelve la ronda.
  void stand() {
    _requirePlayerTurn();
    _playDealerAndSettle();
  }

  /// El jugador dobla: duplica la apuesta, recibe exactamente una carta y se
  /// planta automáticamente.
  void doubleDown() {
    _requirePlayerTurn();
    if (!availableActions.contains(PlayerAction.doubleDown)) {
      throw StateError('Doblar no está permitido en este estado.');
    }
    _bet *= 2;
    _doubled = true;
    _player = _player.add(shoe.deal());
    if (_player.isBust) {
      _phase = RoundPhase.settled;
      _outcome = HandOutcome.dealerWin;
      return;
    }
    _playDealerAndSettle();
  }

  /// El jugador se rinde: la ronda termina y recupera la mitad de la apuesta.
  void surrender() {
    _requirePlayerTurn();
    if (!availableActions.contains(PlayerAction.surrender)) {
      throw StateError('Rendirse no está permitido en este estado.');
    }
    _phase = RoundPhase.settled;
    _outcome = HandOutcome.surrendered;
  }

  /// Juega la mano del crupier según las reglas y resuelve el resultado.
  void _playDealerAndSettle() {
    _phase = RoundPhase.dealerTurn;

    // El crupier pide hasta 17; con 17 suave sigue o se planta según la regla.
    while (_shouldDealerHit()) {
      _dealer = _dealer.add(shoe.deal());
    }

    _outcome = _resolve();
    _phase = RoundPhase.settled;
  }

  bool _shouldDealerHit() {
    final total = _dealer.total;
    if (total < 17) return true;
    if (total == 17 && _dealer.isSoft && rules.dealerSoft17 == Soft17.hit) {
      return true;
    }
    return false;
  }

  HandOutcome _resolve() {
    // Caso sin peek: el crupier podría tener blackjack natural.
    final dealerBJ = _dealer.isBlackjack;
    final playerBJ = _player.isBlackjack;
    if (playerBJ && dealerBJ) return HandOutcome.push;
    if (playerBJ) return HandOutcome.playerBlackjack;
    if (dealerBJ) return HandOutcome.dealerWin;

    if (_player.isBust) return HandOutcome.dealerWin;
    if (_dealer.isBust) return HandOutcome.playerWin;

    final p = _player.total;
    final d = _dealer.total;
    if (p > d) return HandOutcome.playerWin;
    if (p < d) return HandOutcome.dealerWin;
    return HandOutcome.push;
  }

  /// Cambio neto en las fichas del jugador según el resultado y la apuesta.
  ///
  /// Convención: el retorno es la ganancia/pérdida **neta** respecto a la
  /// apuesta puesta en esta mano (ya refleja el doblado, porque [_bet] se
  /// duplicó). Blackjack natural paga según la mesa (p. ej. 3:2).
  int get netChips {
    if (_phase != RoundPhase.settled || _outcome == null) {
      throw StateError('La ronda aún no está resuelta.');
    }
    switch (_outcome!) {
      case HandOutcome.playerBlackjack:
        // La apuesta de un blackjack nunca se dobla; usa la apuesta base.
        return (_bet * rules.blackjackPayoutMultiplier).round();
      case HandOutcome.playerWin:
        return _bet;
      case HandOutcome.dealerWin:
        return -_bet;
      case HandOutcome.push:
        return 0;
      case HandOutcome.surrendered:
        // Recupera la mitad: pierde la mitad de la apuesta base (no doblada).
        return -(_bet ~/ 2);
    }
  }

  /// Indica si esta mano se jugó doblada.
  bool get wasDoubled => _doubled;

  void _requirePlayerTurn() {
    if (_phase != RoundPhase.playerTurn) {
      throw StateError('No es el turno del jugador (fase actual: $_phase).');
    }
  }
}
