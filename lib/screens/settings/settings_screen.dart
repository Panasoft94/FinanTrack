import 'package:budget/screens/config/base_config_screen.dart';
import 'package:budget/screens/database/reset_database_screen.dart';
import 'package:budget/screens/database/restore_database_screen.dart';
import 'package:budget/screens/database/save_database_screen.dart';
import 'package:budget/screens/devises/devises_screen.dart';
import 'package:budget/screens/dictionnaire/dictionnaire_screen.dart';
import 'package:budget/screens/user_account/user_account_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildSectionHeader('Général'),
          _buildDashboardTile(
            context,
            icon: Icons.currency_exchange,
            title: 'Devises',
            subtitle: 'Gérer les monnaies utilisées',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const DevisesScreen()));
            },
          ),
          _buildDashboardTile(
            context,
            icon: Icons.settings_applications,
            title: 'Configuration de base',
            subtitle: 'Paramètres système du compte',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const BaseConfigScreen()));
            },
          ),
          _buildDashboardTile(
            context,
            icon: Icons.account_circle,
            title: 'Gérer votre compte',
            subtitle: 'Profil et sécurité',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const UserAccountScreen()));
            },
          ),
          _buildSectionHeader('Outils'),
          _buildDashboardTile(
            context,
            icon: Icons.book,
            title: 'Dictionnaire',
            subtitle: 'Gérer vos descriptions types',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const DictionnaireScreen()));
            },
          ),
          _buildSectionHeader('Données'),
          _buildDashboardTile(
            context,
            icon: Icons.save,
            title: 'Sauvegarder la base',
            subtitle: 'Exporter vos données locales',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const SaveDatabaseScreen()));
            },
          ),
          _buildDashboardTile(
            context,
            icon: Icons.restore,
            title: 'Restaurer la base',
            subtitle: 'Importer une sauvegarde existante',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const RestoreDatabaseScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAlertTile(
            context,
            icon: Icons.delete_forever,
            title: 'Réinitialiser la base',
            subtitle: 'Effacer toutes vos données',
            onTap: () {
              _showResetDialog(context);
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version 1.2.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 24.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
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

  Widget _buildDashboardTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: Colors.green),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlertTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: Colors.red[700]),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[900])),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.red[300])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.red[200]),
              ],
            ),
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
