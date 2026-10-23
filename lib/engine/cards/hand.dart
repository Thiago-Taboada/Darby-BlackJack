import 'playing_card.dart';

/// Una mano de Blackjack: una lista ordenada de cartas con el cálculo del total
/// usando el valor flexible del as.
///
/// El total se calcula sumando los valores de las cartas (el as como 11) y
/// restando 10 por cada as mientras el total supere 21. Así el as vale 11
/// cuando cabe y 1 cuando no, que es la regla real del Blackjack.
///
/// La mano es inmutable: [add] devuelve una mano nueva. Esto encaja con un motor
/// basado en estados inmutables y facilita las pruebas.
class Hand {
  const Hand(this.cards);

  /// Crea una mano vacía.
  const Hand.empty() : cards = const [];

  final List<PlayingCard> cards;

  /// Devuelve una nueva mano con [card] añadida al final.
  Hand add(PlayingCard card) => Hand([...cards, card]);

  /// Número de cartas en la mano.
  int get length => cards.length;

  /// Mejor total posible sin pasarse de 21 cuando es posible.
  ///
  /// Suma los ases como 11 y luego los va bajando a 1 (restando 10) mientras el
  /// total supere 21 y queden ases "altos" por ajustar.
  int get total {
    var sum = 0;
    var aces = 0;
    for (final card in cards) {
      sum += card.blackjackValue;
      if (card.isAce) aces++;
    }
    while (sum > 21 && aces > 0) {
      sum -= 10;
      aces--;
    }
    return sum;
  }

  /// Una mano es "suave" (soft) si contiene al menos un as contado como 11.
  ///
  /// Es relevante para las reglas del crupier (plantarse o pedir con 17 suave).
  bool get isSoft {
    var sum = 0;
    var aces = 0;
    for (final card in cards) {
      sum += card.blackjackValue;
      if (card.isAce) aces++;
    }
    // Baja ases solo mientras nos pasemos de 21; si al final queda algún as
    // contado como 11 (es decir, no se bajaron todos), la mano es suave.
    var highAces = aces;
    while (sum > 21 && highAces > 0) {
      sum -= 10;
      highAces--;
    }
    return highAces > 0;
  }

  /// Indica si la mano se ha pasado de 21.
  bool get isBust => total > 21;

  /// Blackjack natural: exactamente dos cartas que suman 21 (un as + un 10/figura).
  bool get isBlackjack => cards.length == 2 && total == 21;

  /// Indica si la mano es una pareja (dos cartas del mismo rango), para split.
  bool get isPair => cards.length == 2 && cards[0].rank == cards[1].rank;

  @override
  String toString() =>
      '${cards.map((c) => c.label).join(' ')} (${isSoft ? 'soft ' : ''}$total)';
}
