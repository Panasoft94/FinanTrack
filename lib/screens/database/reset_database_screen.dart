import 'package:flutter/material.dart';

class ResetDatabaseScreen extends StatelessWidget {
  const ResetDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning),
            SizedBox(width: 8),
            Text('Réinitialiser la base'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildResetTile(
            context,
            title: 'Réinitialiser les Comptes',
            onTap: () => _showConfirmationDialog(context, 'Comptes'),
          ),
          const SizedBox(height: 16),
          _buildResetTile(
            context,
            title: 'Réinitialiser les Catégories',
            onTap: () => _showConfirmationDialog(context, 'Catégories'),
          ),
          const SizedBox(height: 16),
          _buildResetTile(
            context,
            title: 'Réinitialiser les Transactions',
            onTap: () => _showConfirmationDialog(context, 'Transactions'),
          ),
          const SizedBox(height: 16),
          _buildResetTile(
            context,
            title: 'Réinitialiser les Budgets',
            onTap: () => _showConfirmationDialog(context, 'Budgets'),
          ),
          const SizedBox(height: 16),
          _buildResetTile(
            context,
            title: 'Réinitialiser les Utilisateurs',
            onTap: () => _showConfirmationDialog(context, 'Utilisateurs'),
          ),
          const SizedBox(height: 16),
          _buildResetTile(
            context,
            title: 'Réinitialiser la Configuration',
            onTap: () => _showConfirmationDialog(context, 'Configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetTile(BuildContext context, {required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple respects the border radius
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.delete_forever, size: 40, color: Colors.red[700]),
        title: Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[900]),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text('Confirmation requise'),
              ),
            ],
          ),
          content: Text('Êtes-vous sûr de vouloir supprimer les données de la table \'$item\' ? Cette action est irréversible.'),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[800],
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Supprimer'),
              onPressed: () {
                // Mettez ici la logique de suppression pour l'élément 'item'
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Données de la table \'$item\' supprimées.'),
                    backgroundColor: Colors.green[700],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }
}
