import '../cards/rank.dart';

/// Un sistema de conteo de cartas.
///
/// Abstrae "cuánto suma o resta cada carta" para poder añadir sistemas más
/// avanzados (KO, Omega II, Hi-Opt, etc.) sin tocar el motor del conteo. El
/// contador ([CardCounter]) solo necesita el valor de cada carta y si el sistema
/// se equilibra (balanced), que determina cómo se calcula el conteo verdadero.
abstract interface class CountingSystem {
  /// Nombre legible del sistema (p. ej. "Hi-Lo").
  String get name;

  /// Valor de conteo que aporta una carta de este [rank].
  int valueOf(Rank rank);

  /// Indica si el sistema está equilibrado (la suma de todos los valores de una
  /// baraja es 0). Los sistemas equilibrados usan el conteo verdadero
  /// (running / barajas restantes); los no equilibrados se interpretan distinto.
  bool get isBalanced;
}
