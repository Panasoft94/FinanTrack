import 'package:flutter/material.dart';

class DataStatisticsScreen extends StatelessWidget {
  const DataStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistique des données'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Écran des statistiques des données'),
      ),
    );
  }
}
