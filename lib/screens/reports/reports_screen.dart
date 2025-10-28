import 'package:flutter/material.dart';
import 'dart:async';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isDownloading = false;
  String _downloadMessage = '';

  Future<void> _performDownload(String format) async {
    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Préparation de votre rapport $format...';
    });

    // Simule une opération de téléchargement
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isDownloading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport $format téléchargé avec succès !'),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Section Filtres ---
            _buildFilterSection(context),
            const SizedBox(height: 20),
            
            // --- Section Aperçu ---
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: _isDownloading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(_downloadMessage),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey[400]),
                             const SizedBox(height: 20),
                             Text(
                              'Aperçu du rapport',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            // --- Section Actions ---
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Période:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            TextButton.icon(
              onPressed: () { /* Logique pour choisir la date de début */ },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text('Date de début'),
            ),
            TextButton.icon(
              onPressed: () { /* Logique pour choisir la date de fin */ },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Date de fin'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF'),
            onPressed: _isDownloading ? null : () => _performDownload('PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.grid_on_outlined),
            label: const Text('Excel'),
            onPressed: _isDownloading ? null : () => _performDownload('Excel'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
