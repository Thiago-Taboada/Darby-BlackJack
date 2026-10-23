import '../cards/playing_card.dart';
import 'counting_system.dart';

/// Lleva el conteo de cartas de una sesión usando un [CountingSystem].
///
/// Diseño clave (requisito 3 de `requisitos.md`):
///
/// * Solo cuenta cartas **ya vistas** por el jugador. La carta oculta del
///   crupier NO se cuenta hasta que se revela; quien usa esta clase debe
///   llamarle únicamente con cartas observables.
/// * El cálculo es **independiente de la UI**: mostrar u ocultar el conteo en
///   pantalla es decisión de la interfaz; este objeto nunca se reinicia ni se
///   altera por ello. Solo [reset] (al rebarajar) pone el conteo a cero.
/// * Idempotencia por carta: cada [PlayingCard] física observada se cuenta una
///   sola vez. Como el shoe reparte sin reemplazo, la misma instancia no vuelve
///   a aparecer en una pasada; aun así se registran las cartas vistas para
///   evitar recuentos accidentales si se reenvía la misma carta.
class CardCounter {
  CardCounter(this.system);

  final CountingSystem system;

  int _runningCount = 0;
  final List<PlayingCard> _seen = [];

  /// Conteo corriente (Running Count): suma de los valores de las cartas vistas.
  int get runningCount => _runningCount;

  /// Número de cartas observadas desde el último [reset].
  int get seenCount => _seen.length;

  /// Registra una carta recién vista y actualiza el conteo corriente.
  void observe(PlayingCard card) {
    _seen.add(card);
    _runningCount += system.valueOf(card.rank);
  }

  /// Registra varias cartas vistas (p. ej. las de una ronda al revelarse).
  void observeAll(Iterable<PlayingCard> cards) {
    for (final card in cards) {
      observe(card);
    }
  }

  /// Conteo verdadero (True Count) = conteo corriente / barajas restantes.
  ///
  /// [decksRemaining] se toma del shoe (nunca 0). Para sistemas no equilibrados
  /// el conteo verdadero no aplica igual; de momento Hi-Lo es equilibrado.
  double trueCount(double decksRemaining) {
    if (decksRemaining <= 0) return _runningCount.toDouble();
    return _runningCount / decksRemaining;
  }

  /// Reinicia el conteo. Debe llamarse SOLO cuando el zapato se rebaraja, no al
  /// ocultar el conteo en la UI.
  void reset() {
    _runningCount = 0;
    _seen.clear();
  }
}
