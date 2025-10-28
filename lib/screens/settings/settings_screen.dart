import 'package:budget/screens/database/reset_database_screen.dart';
import 'package:budget/screens/database/restore_database_screen.dart';
import 'package:budget/screens/database/save_database_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardTile(
            context,
            icon: Icons.save,
            title: 'Sauvegarder la base',
            onTap: () {
              Navigator.of(context).push(_createFadeRoute(const SaveDatabaseScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.restore,
            title: 'Restaurer la base',
            onTap: () {
              Navigator.of(context).push(_createFadeRoute(const RestoreDatabaseScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.refresh,
            title: 'Réinitialiser la base',
            onTap: () {
              Navigator.of(context).push(_createFadeRoute(const ResetDatabaseScreen()));
            },
          ),
        ],
      ),
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
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
