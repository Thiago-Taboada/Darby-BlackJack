import 'package:flutter/material.dart';

import '../../../engine/cards/cards.dart';

/// Dibuja una carta de la mesa. Si [card] es null o [faceDown] es true, muestra
/// el reverso (usado para la carta oculta del crupier).
class CardWidget extends StatelessWidget {
  const CardWidget({super.key, this.card, this.faceDown = false});

  final PlayingCard? card;
  final bool faceDown;

  bool get _isRed =>
      card != null && (card!.suit == Suit.hearts || card!.suit == Suit.diamonds);

  @override
  Widget build(BuildContext context) {
    const width = 64.0;
    const height = 92.0;

    if (faceDown || card == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A6B), Color(0xFF0D1F3C)],
          ),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Icon(Icons.casino, color: Colors.white38, size: 28),
        ),
      );
    }

    final color = _isRed ? const Color(0xFFD32F2F) : const Color(0xFF212121);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card!.rank.symbol,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Expanded(
            child: Center(
              child: Text(card!.suit.glyph, style: TextStyle(color: color, fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }
}
