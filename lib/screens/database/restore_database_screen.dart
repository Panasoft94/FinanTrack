import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class RestoreDatabaseScreen extends StatefulWidget {
  const RestoreDatabaseScreen({super.key});

  @override
  State<RestoreDatabaseScreen> createState() => _RestoreDatabaseScreenState();
}

class _RestoreDatabaseScreenState extends State<RestoreDatabaseScreen> {
  bool _isRestoring = false;
  String? _selectedBackupPath;
  late Future<List<File>> _backupsFuture;

  @override
  void initState() {
    super.initState();
    _backupsFuture = _findBackups();
  }

  Future<List<File>> _findBackups() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (status.isGranted) {
      final backupDir = Directory("/storage/emulated/0/Download/FinanTrackBackups");
      if (await backupDir.exists()) {
        return backupDir.listSync().whereType<File>().where((file) => file.path.endsWith('.db')).toList();
      }
    }
    return [];
  }

  Future<void> _performRestore() async {
    if (_selectedBackupPath == null) return;

    setState(() {
      _isRestoring = true;
    });

    final dbHelper = DbHelper();
    final success = await dbHelper.restorer(_selectedBackupPath!);

    setState(() {
      _isRestoring = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Restauration réussie ! Veuillez redémarrer l\'application.' : 'Échec de la restauration.'),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
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
              'Choisissez une sauvegarde pour restaurer vos données. Attention, les données actuelles non sauvegardées seront perdues.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            FutureBuilder<List<File>>(
              future: _backupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Aucune sauvegarde trouvée."));
                }
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Choisir une sauvegarde',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.archive_outlined),
                  ),
                  value: _selectedBackupPath,
                  items: snapshot.data!.map((file) {
                    return DropdownMenuItem<String>(
                      value: file.path,
                      child: Text(
                        p.basename(file.path),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedBackupPath = newValue;
                    });
                  },
                );
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
                onPressed: _selectedBackupPath == null ? null : _performRestore,
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
