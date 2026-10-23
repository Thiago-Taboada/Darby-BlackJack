/// Resultado de una comprobación de conteo del jugador.
class CountCheck {
  const CountCheck({
    required this.guess,
    required this.actual,
    required this.wasCorrect,
  });

  /// Lo que el jugador creía que era el conteo corriente.
  final int guess;

  /// El conteo corriente real en ese momento.
  final int actual;

  /// Si el jugador acertó exactamente.
  final bool wasCorrect;

  /// Diferencia (positiva o negativa) entre la respuesta y el valor real.
  int get error => guess - actual;
}

/// Lleva las estadísticas de precisión del jugador al practicar el conteo.
///
/// Compara la respuesta del jugador (lo que cree que es el running count) con
/// el valor real y acumula aciertos, errores y racha. Es Dart puro y no sabe
/// nada de la UI. Da soporte a los modos de entrenamiento (requisito 4) y a las
/// métricas de precisión del conteo (requisito 8).
class CountTrainer {
  int _checks = 0;
  int _correct = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalAbsError = 0;
  CountCheck? _lastCheck;

  /// Número de comprobaciones realizadas.
  int get checks => _checks;

  /// Número de aciertos exactos.
  int get correct => _correct;

  /// Racha actual de aciertos consecutivos.
  int get currentStreak => _currentStreak;

  /// Mejor racha de aciertos consecutivos.
  int get bestStreak => _bestStreak;

  /// Última comprobación realizada, o null si aún no hay ninguna.
  CountCheck? get lastCheck => _lastCheck;

  /// Precisión como fracción en [0, 1]. 0 si aún no hay comprobaciones.
  double get accuracy => _checks == 0 ? 0 : _correct / _checks;

  /// Error absoluto medio por comprobación. 0 si aún no hay comprobaciones.
  double get meanAbsoluteError => _checks == 0 ? 0 : _totalAbsError / _checks;

  /// Comprueba la respuesta del jugador contra el conteo corriente real y
  /// actualiza las estadísticas. Devuelve el detalle de la comprobación.
  CountCheck check({required int guess, required int actual}) {
    final correct = guess == actual;
    _checks++;
    if (correct) {
      _correct++;
      _currentStreak++;
      if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
    } else {
      _currentStreak = 0;
    }
    _totalAbsError += (guess - actual).abs();
    final result = CountCheck(guess: guess, actual: actual, wasCorrect: correct);
    _lastCheck = result;
    return result;
  }

  /// Reinicia todas las estadísticas (p. ej. al empezar una sesión nueva).
  void reset() {
    _checks = 0;
    _correct = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _totalAbsError = 0;
    _lastCheck = null;
  }
}
