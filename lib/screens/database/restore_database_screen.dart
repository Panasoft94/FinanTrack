import 'package:flutter/material.dart';

class RestoreDatabaseScreen extends StatelessWidget {
  const RestoreDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurer la base'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Écran de restauration de la base de données'),
      ),
    );
  }
}
