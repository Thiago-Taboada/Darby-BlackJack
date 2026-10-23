/// Comportamiento del crupier con un 17 suave (soft 17).
enum Soft17 {
  /// El crupier se planta con cualquier 17, incluido el 17 suave (S17).
  stand,

  /// El crupier pide carta con 17 suave (H17); se planta con 17 duro.
  hit,
}

/// Reglas configurables de la mesa de Blackjack.
///
/// Mantiene separada la configuración (qué permite la mesa y cómo paga) del
/// motor que la aplica. Es inmutable: para cambiar una regla se crea una copia
/// con [copyWith]. Incluye presets habituales ([beginner], [advanced]).
///
/// Cubre el requisito 5 de `requisitos.md`.
class TableRules {
  const TableRules({
    this.deckCount = 6,
    this.penetration = 0.75,
    this.dealerSoft17 = Soft17.stand,
    this.blackjackPayoutNumerator = 3,
    this.blackjackPayoutDenominator = 2,
    this.allowDouble = true,
    this.allowDoubleAfterSplit = true,
    this.allowSplit = true,
    this.maxSplitHands = 4,
    this.dealerPeeks = true,
    this.allowSurrender = false,
    this.minBet = 1,
    this.maxBet = 500,
  })  : assert(blackjackPayoutDenominator > 0),
        assert(minBet > 0 && maxBet >= minBet),
        assert(maxSplitHands >= 1);

  /// Número de barajas del zapato (1, 2, 4, 6 u 8).
  final int deckCount;

  /// Penetración del zapato antes de la carta de corte (fracción en (0, 1]).
  final double penetration;

  /// Qué hace el crupier con un 17 suave.
  final Soft17 dealerSoft17;

  /// Pago del blackjack natural como fracción numerador/denominador.
  /// Por defecto 3:2. Para 6:5 usar 6 y 5.
  final int blackjackPayoutNumerator;
  final int blackjackPayoutDenominator;

  /// Si se permite doblar la apuesta.
  final bool allowDouble;

  /// Si se permite doblar después de dividir (DAS).
  final bool allowDoubleAfterSplit;

  /// Si se permite dividir parejas.
  final bool allowSplit;

  /// Número máximo de manos resultantes de dividir (p. ej. 4).
  final int maxSplitHands;

  /// Si el crupier comprueba blackjack al mostrar un as o una carta de 10.
  final bool dealerPeeks;

  /// Si se permite la rendición (surrender).
  final bool allowSurrender;

  /// Apuesta mínima y máxima permitidas en la mesa.
  final int minBet;
  final int maxBet;

  /// Multiplicador de pago del blackjack natural (p. ej. 1.5 para 3:2).
  double get blackjackPayoutMultiplier =>
      blackjackPayoutNumerator / blackjackPayoutDenominator;

  /// Preset recomendado para principiantes: reglas favorables al jugador.
  static const TableRules beginner = TableRules(
    deckCount: 2,
    penetration: 0.75,
    dealerSoft17: Soft17.stand,
    blackjackPayoutNumerator: 3,
    blackjackPayoutDenominator: 2,
    allowDouble: true,
    allowDoubleAfterSplit: true,
    allowSplit: true,
    maxSplitHands: 4,
    dealerPeeks: true,
    allowSurrender: true,
  );

  /// Preset avanzado: reglas más exigentes, típicas de zapato de 6-8 barajas.
  static const TableRules advanced = TableRules(
    deckCount: 6,
    penetration: 0.75,
    dealerSoft17: Soft17.hit,
    blackjackPayoutNumerator: 3,
    blackjackPayoutDenominator: 2,
    allowDouble: true,
    allowDoubleAfterSplit: false,
    allowSplit: true,
    maxSplitHands: 4,
    dealerPeeks: true,
    allowSurrender: false,
  );

  TableRules copyWith({
    int? deckCount,
    double? penetration,
    Soft17? dealerSoft17,
    int? blackjackPayoutNumerator,
    int? blackjackPayoutDenominator,
    bool? allowDouble,
    bool? allowDoubleAfterSplit,
    bool? allowSplit,
    int? maxSplitHands,
    bool? dealerPeeks,
    bool? allowSurrender,
    int? minBet,
    int? maxBet,
  }) {
    return TableRules(
      deckCount: deckCount ?? this.deckCount,
      penetration: penetration ?? this.penetration,
      dealerSoft17: dealerSoft17 ?? this.dealerSoft17,
      blackjackPayoutNumerator:
          blackjackPayoutNumerator ?? this.blackjackPayoutNumerator,
      blackjackPayoutDenominator:
          blackjackPayoutDenominator ?? this.blackjackPayoutDenominator,
      allowDouble: allowDouble ?? this.allowDouble,
      allowDoubleAfterSplit:
          allowDoubleAfterSplit ?? this.allowDoubleAfterSplit,
      allowSplit: allowSplit ?? this.allowSplit,
      maxSplitHands: maxSplitHands ?? this.maxSplitHands,
      dealerPeeks: dealerPeeks ?? this.dealerPeeks,
      allowSurrender: allowSurrender ?? this.allowSurrender,
      minBet: minBet ?? this.minBet,
      maxBet: maxBet ?? this.maxBet,
    );
  }
}
