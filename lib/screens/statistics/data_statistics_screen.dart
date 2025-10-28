import 'package:flutter/material.dart';

class DataStatisticsScreen extends StatelessWidget {
  const DataStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.analytics),
            SizedBox(width: 8),
            Text('Statistique des données'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Écran des statistiques des données'),
      ),
    );
  }
}
