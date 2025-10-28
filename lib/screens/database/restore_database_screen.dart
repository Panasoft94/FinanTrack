import 'package:flutter/material.dart';
import 'dart:async';

class RestoreDatabaseScreen extends StatefulWidget {
  const RestoreDatabaseScreen({super.key});

  @override
  State<RestoreDatabaseScreen> createState() => _RestoreDatabaseScreenState();
}

class _RestoreDatabaseScreenState extends State<RestoreDatabaseScreen> {
  bool _isRestoring = false;
  String? _selectedBackup;
  // Simule une liste de sauvegardes disponibles
  final List<String> _availableBackups = [
    'Sauvegarde du 2023-10-27',
    'Sauvegarde du 2023-10-20',
    'Sauvegarde du 2023-10-15',
  ];

  Future<void> _performRestore() async {
    if (_selectedBackup == null) return;

    setState(() {
      _isRestoring = true;
    });

    // Simule une opération de restauration de 3 secondes
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isRestoring = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restauration à partir de "$_selectedBackup" réussie !'),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.restore),
            SizedBox(width: 8),
            Text('Restaurer la base'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              Icons.history,
              size: 120,
              color: Colors.green.withOpacity(0.8),
            ),
            const SizedBox(height: 30),
            const Text(
              'Restaurer les données',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              'Choisissez une sauvegarde pour restaurer vos données à un état antérieur. Attention, les données actuelles non sauvegardées seront perdues.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Choisir une sauvegarde',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.archive_outlined),
              ),
              value: _selectedBackup,
              items: _availableBackups.map((String backup) {
                return DropdownMenuItem<String>(
                  value: backup,
                  child: Text(backup),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedBackup = newValue;
                });
              },
            ),
            const SizedBox(height: 30),
            if (_isRestoring)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Restauration en cours...'),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.restore_page_rounded),
                label: const Text('Lancer la restauration'),
                onPressed: _selectedBackup == null ? null : _performRestore, // Désactivé si aucune sauvegarde n'est choisie
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
