import 'dart:math';

import '../cards/playing_card.dart';
import '../cards/rank.dart';
import '../cards/suit.dart';

/// El zapato (shoe): el conjunto de barajas desde el que se reparten cartas.
///
/// Es el corazón del simulador. Modela el comportamiento de un casino real:
///
/// * Se construye con N barajas reales (1, 2, 4, 6 u 8), cada una con sus 52
///   cartas (4 palos × 13 rangos).
/// * Se mezcla de forma aleatoria pero reproducible (se puede sembrar el
///   generador para que los tests y las simulaciones sean deterministas).
/// * **Reparte sin reemplazo**: cada carta repartida sale del zapato y no vuelve
///   a aparecer hasta el siguiente barajado.
/// * Mantiene el registro de cartas repartidas y restantes, y la composición
///   (cuántas cartas de cada rango quedan) para calcular probabilidades y el
///   conteo verdadero.
/// * Tiene una **carta de corte** (cut card) configurable mediante la
///   penetración: cuando el reparto la cruza, se marca que hay que rebarajar al
///   final de la ronda ([needsReshuffle]).
///
/// Es Dart puro: no depende de Flutter ni de Firebase.
class Shoe {
  /// Crea y mezcla un zapato.
  ///
  /// [deckCount] debe ser uno de los valores admitidos (1, 2, 4, 6, 8).
  /// [penetration] es la fracción del zapato que se reparte antes de la carta de
  /// corte (p. ej. 0.75 = se juega el 75% y se rebaraja). Debe estar en (0, 1].
  /// [random] permite inyectar un generador sembrado para reproducibilidad.
  Shoe({required this.deckCount, this.penetration = 0.75, Random? random})
    : assert(
        allowedDeckCounts.contains(deckCount),
        'deckCount debe ser uno de $allowedDeckCounts',
      ),
      assert(
        penetration > 0 && penetration <= 1,
        'penetration debe estar en (0, 1]',
      ),
      _random = random ?? Random() {
    reshuffle();
  }

  /// Crea un zapato con un orden de cartas predefinido, para pruebas.
  ///
  /// Las cartas se reparten en el orden dado ([scripted.first] sale primero).
  /// No mezcla y no usa barajas completas: sirve para escribir escenarios de
  /// juego deterministas en los tests del motor. No usar en producción.
  Shoe.scripted(List<PlayingCard> scripted)
    : deckCount = 1,
      penetration = 1,
      _random = Random(0) {
    // _undealt reparte desde el final, así que invertimos para que el primer
    // elemento de `scripted` sea el primero en salir.
    _undealt.addAll(scripted.reversed);
    _cutIndex = scripted.length;
  }

  /// Números de barajas admitidos por las reglas de la mesa.
  static const List<int> allowedDeckCounts = [1, 2, 4, 6, 8];

  /// Número de cartas en una baraja completa.
  static const int cardsPerDeck = 52;

  final int deckCount;
  final double penetration;
  final Random _random;

  /// Cartas que aún no se han repartido, en el orden en que saldrán (la próxima
  /// carta a repartir es la última de la lista, para que sacar sea O(1)).
  final List<PlayingCard> _undealt = [];

  /// Cartas ya repartidas en esta pasada del zapato, en orden de reparto.
  final List<PlayingCard> _dealt = [];

  /// Índice (contado desde el inicio de la pasada) donde está la carta de corte.
  late int _cutIndex;

  /// Número total de cartas del zapato (barajas × 52).
  int get totalCards => deckCount * cardsPerDeck;

  /// Cartas que quedan por repartir.
  int get cardsRemaining => _undealt.length;

  /// Cartas repartidas desde el último barajado.
  int get cardsDealt => _dealt.length;

  /// Estimación de barajas restantes, usada para el conteo verdadero (True
  /// Count = Running Count / barajas restantes). Nunca devuelve 0 para evitar
  /// divisiones por cero; se acota a un mínimo de un cuarto de baraja.
  double get decksRemaining {
    final decks = cardsRemaining / cardsPerDeck;
    return decks < 0.25 ? 0.25 : decks;
  }

  /// Indica si el reparto ha cruzado la carta de corte y, por tanto, hay que
  /// rebarajar (normalmente al terminar la ronda en curso).
  bool get needsReshuffle => _dealt.length >= _cutIndex;

  /// Copia de solo lectura de las cartas ya repartidas (para historial/análisis).
  List<PlayingCard> get dealtCards => List.unmodifiable(_dealt);

  /// Composición actual del zapato: cuántas cartas de cada rango quedan.
  ///
  /// Base para calcular probabilidades a partir de la composición real de las
  /// cartas restantes (no de una baraja teórica).
  Map<Rank, int> get composition {
    final counts = {for (final rank in Rank.values) rank: 0};
    for (final card in _undealt) {
      counts[card.rank] = counts[card.rank]! + 1;
    }
    return counts;
  }

  /// Reconstruye el zapato con todas sus cartas, lo mezcla y coloca la carta de
  /// corte según la penetración. Se llama al crear el zapato y cuando procede
  /// rebarajar.
  void reshuffle() {
    _undealt.clear();
    _dealt.clear();
    for (var deck = 0; deck < deckCount; deck++) {
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          _undealt.add(PlayingCard(rank, suit));
        }
      }
    }
    _shuffle();
    // Penetración 0.75 => se reparten ~75% de las cartas antes de rebarajar.
    _cutIndex = (totalCards * penetration).floor().clamp(1, totalCards);
  }

  /// Mezcla de Fisher–Yates sobre las cartas no repartidas usando [_random].
  void _shuffle() {
    for (var i = _undealt.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = _undealt[i];
      _undealt[i] = _undealt[j];
      _undealt[j] = tmp;
    }
  }

  /// Reparte la siguiente carta del zapato, retirándola del conjunto disponible.
  ///
  /// Lanza [StateError] si el zapato está vacío: el motor del juego debe
  /// rebarajar cuando corresponda ([needsReshuffle]) antes de agotarlo.
  PlayingCard deal() {
    if (_undealt.isEmpty) {
      throw StateError(
        'El zapato está vacío; hay que rebarajar antes de repartir.',
      );
    }
    final card = _undealt.removeLast();
    _dealt.add(card);
    return card;
  }
}
