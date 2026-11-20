import 'package:flutter/material.dart';
import 'screens/bacheca_screen.dart';

void main() {
  runApp(const BachecaApp());
}

class BachecaApp extends StatelessWidget {
  const BachecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Annunci Lavoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BachecaScreen(),
    );
  }
}