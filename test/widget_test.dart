import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darby_blackjack/main.dart';

void main() {
  testWidgets('La mesa arranca en fase de apuesta', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DarbyBlackjackApp()));

    // Título en la AppBar.
    expect(find.text('Darby Blackjack'), findsOneWidget);
    // Mensaje inicial de apuesta.
    expect(find.text('Haz tu apuesta y reparte.'), findsOneWidget);
    // Botón de repartir disponible al inicio.
    expect(find.textContaining('Repartir'), findsOneWidget);
  });
}
