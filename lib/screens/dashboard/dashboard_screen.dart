import 'package:budget/screens/accounts/accounts_screen.dart';
import 'package:budget/screens/notifications/notifications_screen.dart';
import 'package:budget/screens/onboarding/onboarding_screen.dart';
import 'package:budget/screens/settings/settings_screen.dart';
import 'package:budget/screens/statistics/data_statistics_screen.dart';
import 'package:budget/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardTile(
            context,
            icon: Icons.swap_horiz,
            title: 'Transactions',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const TransactionsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.analytics,
            title: 'Statistique des données',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const DataStatisticsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.settings,
            title: 'Paramètres',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const SettingsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const NotificationsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Gérer les comptes',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const AccountsScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showExitDialog(context);
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.exit_to_app),
        tooltip: 'Quitter',
      ),
    );
  }
  
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: const [
              Icon(Icons.exit_to_app, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text('Confirmation'),
              ),
            ],
          ),
          content: const Text('Voulez-vous vraiment quitter et retourner à l\'accueil ?'),
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
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Quitter'),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  (Route<dynamic> route) => false,
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
