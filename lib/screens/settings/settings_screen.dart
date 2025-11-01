import 'package:budget/screens/config/base_config_screen.dart';
import 'package:budget/screens/database/reset_database_screen.dart';
import 'package:budget/screens/database/restore_database_screen.dart';
import 'package:budget/screens/database/save_database_screen.dart';
import 'package:budget/screens/devises/devises_screen.dart';
import 'package:budget/screens/user_account/user_account_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Paramètres'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardTile(
            context,
            icon: Icons.currency_exchange,
            title: 'Devises',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const DevisesScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.settings_applications,
            title: 'Configuration de base',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const BaseConfigScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.account_circle,
            title: 'Gérer le compte utilisateur',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const UserAccountScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.save,
            title: 'Sauvegarder la base',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const SaveDatabaseScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.restore,
            title: 'Restaurer la base',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const RestoreDatabaseScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildAlertTile(
            context,
            icon: Icons.warning,
            title: 'Réinitialiser la base',
            onTap: () {
              _showResetDialog(context);
            },
          ),
        ],
      ),
    );
  }
  
  void _showResetDialog(BuildContext context) {
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
                child: Text('Attention'),
              ),
            ],
          ),
          content: const Text('Vous êtes sur le point d\'accéder à la zone de réinitialisation. Voulez-vous continuer ?'),
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
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuer'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).push(_slideTransition(const ResetDatabaseScreen()));
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

  Widget _buildDashboardTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 24),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlertTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.red[700]),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[900]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
  }
}
