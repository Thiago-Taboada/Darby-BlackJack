/// Palo de una carta de la baraja francesa.
///
/// El palo no afecta al valor en Blackjack; se mantiene para representar las 52
/// cartas reales de cada baraja y para la presentación visual.
enum Suit {
  clubs('C', '♣'),
  diamonds('D', '♦'),
  hearts('H', '♥'),
  spades('S', '♠');

  const Suit(this.code, this.glyph);

  /// Código de una letra para identificar el palo (C, D, H, S).
  final String code;

  /// Glifo Unicode del palo para mostrar en UI y depuración.
  final String glyph;
}
