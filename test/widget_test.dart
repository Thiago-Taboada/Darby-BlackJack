import 'package:darby_blackjack/data/auth_repository.dart';
import 'package:darby_blackjack/features/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sin sesión, AuthGate muestra la pantalla de inicio de sesión', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Simula "sin usuario" sin tocar Firebase.
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pump(); // resuelve el stream

    expect(find.text('Darby Blackjack'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
  });
}
