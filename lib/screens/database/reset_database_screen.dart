import 'package:flutter/material.dart';

class ResetDatabaseScreen extends StatelessWidget {
  const ResetDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialiser la base'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Écran de réinitialisation de la base de données'),
      ),
    );
  }
}
