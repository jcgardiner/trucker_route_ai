import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TruckerRouteAIApp());
}

class TruckerRouteAIApp extends StatelessWidget {
  const TruckerRouteAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trucker Route AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[800],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 