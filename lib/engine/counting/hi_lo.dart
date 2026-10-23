import '../cards/rank.dart';
import 'counting_system.dart';

/// Sistema de conteo **Hi-Lo**, el más usado para empezar.
///
/// Valores (requisito 3 de `requisitos.md`):
///
/// | Cartas         | Valor |
/// | -------------- | ----- |
/// | 2, 3, 4, 5, 6  | +1    |
/// | 7, 8, 9        | 0     |
/// | 10, J, Q, K, A | −1    |
///
/// Es un sistema **equilibrado**: la suma de los valores de una baraja completa
/// es 0, por lo que se usa el conteo verdadero (running count / barajas
/// restantes) para normalizar según cuántas cartas quedan.
class HiLo implements CountingSystem {
  const HiLo();

  @override
  String get name => 'Hi-Lo';

  @override
  bool get isBalanced => true;

  @override
  int valueOf(Rank rank) {
    switch (rank) {
      case Rank.two:
      case Rank.three:
      case Rank.four:
      case Rank.five:
      case Rank.six:
        return 1;
      case Rank.seven:
      case Rank.eight:
      case Rank.nine:
        return 0;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
      case Rank.ace:
        return -1;
    }
  }
}
