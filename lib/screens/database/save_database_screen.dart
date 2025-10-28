import 'package:flutter/material.dart';
import 'dart:async';

class SaveDatabaseScreen extends StatefulWidget {
  const SaveDatabaseScreen({super.key});

  @override
  State<SaveDatabaseScreen> createState() => _SaveDatabaseScreenState();
}

class _SaveDatabaseScreenState extends State<SaveDatabaseScreen> {
  bool _isSaving = false;
  String _lastBackupInfo = "Jamais sauvegardé"; // Valeur par défaut

  Future<void> _performSave() async {
    setState(() {
      _isSaving = true;
    });

    // Simule une opération de sauvegarde de 3 secondes
    await Future.delayed(const Duration(seconds: 3));

    // Met à jour l'état après la sauvegarde
    setState(() {
      _isSaving = false;
      // Dans une vraie application, vous stockeriez et liriez cette date
      _lastBackupInfo = "Dernière sauvegarde : Aujourd\'hui"; 
    });
    
    // Affiche un message de succès
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sauvegarde de la base de données réussie !'),
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
            Icon(Icons.save),
            SizedBox(width: 8),
            Text('Sauvegarder la base'),
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
              Icons.cloud_upload_outlined,
              size: 120,
              color: Colors.green.withOpacity(0.8),
            ),
            const SizedBox(height: 30),
            const Text(
              'Sauvegarde des données',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              'Protégez vos données en créant une copie de sauvegarde. Vous pourrez la restaurer à tout moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 50),
            if (_isSaving)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Sauvegarde en cours...'),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Lancer la sauvegarde'),
                onPressed: _performSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const Spacer(),
            const Spacer(),
            Text(
              _lastBackupInfo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
