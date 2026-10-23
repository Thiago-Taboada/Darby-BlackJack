import 'rank.dart';
import 'suit.dart';

/// Una carta concreta de la baraja: combinación de [rank] y [suit].
///
/// Es inmutable y tiene igualdad por valor, de modo que dos cartas con el mismo
/// rango y palo se consideran iguales. El shoe garantiza que, dentro de un mismo
/// zapato, cada carta física aparece el número correcto de veces según el número
/// de barajas (no hay cartas repetidas de forma indebida ni inexistentes).
class PlayingCard {
  const PlayingCard(this.rank, this.suit);

  final Rank rank;
  final Suit suit;

  /// Valor en Blackjack del rango (el as vale 11; el ajuste lo hace la mano).
  int get blackjackValue => rank.blackjackValue;

  /// Indica si la carta es un as.
  bool get isAce => rank.isAce;

  /// Representación corta, p. ej. "A♠", "10♦".
  String get label => '${rank.symbol}${suit.glyph}';

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);

  @override
  String toString() => label;
}
