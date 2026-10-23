import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darby_blackjack/main.dart';

void main() {
  testWidgets('La app arranca y muestra el título', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DarbyBlackjackApp()));

    expect(find.text('Darby Blackjack'), findsOneWidget);
    expect(find.text('Etapa 1 — Fundamentos del juego'), findsOneWidget);
  });
}
