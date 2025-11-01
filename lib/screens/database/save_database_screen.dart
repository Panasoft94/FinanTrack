import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SaveDatabaseScreen extends StatefulWidget {
  const SaveDatabaseScreen({super.key});

  @override
  State<SaveDatabaseScreen> createState() => _SaveDatabaseScreenState();
}

class _SaveDatabaseScreenState extends State<SaveDatabaseScreen> {
  bool _isSaving = false;
  String? _backupPath;

  Future<void> _performSave() async {
    setState(() {
      _isSaving = true;
      _backupPath = null;
    });

    final dbHelper = DbHelper();
    final path = await dbHelper.backUp();

    setState(() {
      _isSaving = false;
      _backupPath = path;
    });
    
    if (mounted) {
      final message = path != null 
          ? 'Sauvegarde réussie !'
          : 'Échec de la sauvegarde. Vérifiez les permissions.';
      final color = path != null ? Colors.green[700] : Colors.red[700];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
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
              'Protégez vos données en créant une copie de sauvegarde dans votre dossier de téléchargements.',
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
            if (_backupPath != null)
              Text(
                'Sauvegarde disponible dans: \n$_backupPath',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }
}
