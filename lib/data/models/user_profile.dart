/// Perfil persistente de un usuario en Firestore.
///
/// Agrupa lo que se guarda entre sesiones (requisito 7): saldo de fichas,
/// preferencias de juego y estadísticas de entrenamiento acumuladas. Se
/// mantiene deliberadamente plano y pequeño para quedar holgado dentro de las
/// cuotas del plan gratuito (pocas lecturas/escrituras, un documento por
/// usuario).
class UserProfile {
  const UserProfile({
    required this.balance,
    required this.showCount,
    required this.totalChecks,
    required this.correctChecks,
    required this.bestStreak,
  });

  /// Saldo de fichas virtuales.
  final int balance;

  /// Preferencia de mostrar el conteo en modo libre.
  final bool showCount;

  /// Estadísticas de precisión del conteo acumuladas entre sesiones.
  final int totalChecks;
  final int correctChecks;
  final int bestStreak;

  /// Perfil por defecto para un usuario recién creado.
  static const UserProfile initial = UserProfile(
    balance: 1000,
    showCount: false,
    totalChecks: 0,
    correctChecks: 0,
    bestStreak: 0,
  );

  /// Precisión acumulada en [0, 1]. 0 si aún no hay comprobaciones.
  double get accuracy => totalChecks == 0 ? 0 : correctChecks / totalChecks;

  UserProfile copyWith({
    int? balance,
    bool? showCount,
    int? totalChecks,
    int? correctChecks,
    int? bestStreak,
  }) {
    return UserProfile(
      balance: balance ?? this.balance,
      showCount: showCount ?? this.showCount,
      totalChecks: totalChecks ?? this.totalChecks,
      correctChecks: correctChecks ?? this.correctChecks,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  Map<String, dynamic> toMap() => {
        'balance': balance,
        'showCount': showCount,
        'totalChecks': totalChecks,
        'correctChecks': correctChecks,
        'bestStreak': bestStreak,
      };

  /// Construye un perfil desde un documento de Firestore, tolerando campos
  /// ausentes (usa los valores por defecto de [initial]).
  factory UserProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return initial;
    return UserProfile(
      balance: (map['balance'] as num?)?.toInt() ?? initial.balance,
      showCount: map['showCount'] as bool? ?? initial.showCount,
      totalChecks: (map['totalChecks'] as num?)?.toInt() ?? 0,
      correctChecks: (map['correctChecks'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}
