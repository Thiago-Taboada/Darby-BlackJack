import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../table/table_screen.dart';
import 'auth_screen.dart';

/// Decide qué pantalla mostrar según el estado de sesión: si hay usuario,
/// la mesa; si no, la pantalla de autenticación. Reacciona en vivo a
/// login/logout gracias a [authStateProvider].
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => user == null ? const AuthScreen() : const TableScreen(),
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0B6B3A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0B6B3A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al iniciar: $e',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
