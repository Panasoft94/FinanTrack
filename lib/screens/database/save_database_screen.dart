import 'package:flutter/material.dart';

class SaveDatabaseScreen extends StatelessWidget {
  const SaveDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarder la base'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Écran de sauvegarde de la base de données'),
      ),
    );
  }
}
