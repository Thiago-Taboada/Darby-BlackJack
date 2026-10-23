/// Acciones que el jugador puede tomar en su turno.
enum PlayerAction { hit, stand, doubleDown, split, surrender }

/// Fase en la que se encuentra la ronda.
enum RoundPhase {
  /// Esperando la apuesta inicial.
  betting,

  /// Turno del jugador (puede pedir, plantarse, doblar...).
  playerTurn,

  /// Turno del crupier (juega automáticamente según las reglas).
  dealerTurn,

  /// Ronda terminada; hay un resultado y un pago calculado.
  settled,
}

/// Resultado de una mano del jugador frente al crupier.
enum HandOutcome {
  /// Blackjack natural del jugador (paga según la mesa, p. ej. 3:2).
  playerBlackjack,

  /// El jugador gana (mejor mano o el crupier se pasa).
  playerWin,

  /// El crupier gana.
  dealerWin,

  /// Empate: se devuelve la apuesta.
  push,

  /// El jugador se rinde (recupera la mitad de la apuesta).
  surrendered,
}
