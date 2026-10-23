import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: DarbyBlackjackApp()));
}

class DarbyBlackjackApp extends StatelessWidget {
  const DarbyBlackjackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darby Blackjack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6B3A), // verde mesa de casino
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Darby Blackjack', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Etapa 1 — Fundamentos del juego'),
          ],
        ),
      ),
    );
  }
}
