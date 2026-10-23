import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/table/table_screen.dart';

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
      home: const TableScreen(),
    );
  }
}
