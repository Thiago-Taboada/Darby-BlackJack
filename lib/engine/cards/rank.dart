/// Rango (valor nominal) de una carta de la baraja francesa.
///
/// El valor en Blackjack es independiente del palo. Las figuras (J, Q, K) y el
/// diez valen 10. El as se modela aquí con su valor "alto" (11); el valor
/// flexible (1 u 11) lo resuelve [Hand] al calcular el total de la mano.
enum Rank {
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('10', 10),
  jack('J', 10),
  queen('Q', 10),
  king('K', 10),
  ace('A', 11);

  const Rank(this.symbol, this.blackjackValue);

  /// Símbolo corto para mostrar en UI y depuración (p. ej. "A", "10", "K").
  final String symbol;

  /// Valor de la carta en Blackjack. Para el as es 11 (valor alto); el ajuste
  /// a 1 cuando conviene lo hace el cálculo del total de la mano.
  final int blackjackValue;

  /// Indica si el rango es un as.
  bool get isAce => this == Rank.ace;
}
