
import 'dart:io';
import 'package:budget/screens/accounts/accounts_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/expense_category/expense_category_screen.dart';
import 'package:budget/screens/guide/guide_screen.dart';
import 'package:budget/screens/login.dart';
import 'package:budget/screens/notifications/notifications_screen.dart';
import 'package:budget/screens/premium/premium_screen.dart';
import 'package:budget/screens/settings/settings_screen.dart';
import 'package:budget/screens/statistics/data_statistics_screen.dart';
import 'package:budget/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final count = await DbHelper.getUnreadNotificationsCount();
    setState(() {
      _unreadNotificationsCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardTile(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Gérer les comptes',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const AccountsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.category,
            title: 'Catégorie depense',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const ExpenseCategoryScreen()));
            },
          ),
          const SizedBox(height: 16),
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
            badgeCount: _unreadNotificationsCount,
            onTap: () {
              Navigator.of(context).push(_slideTransition(const NotificationsScreen())).then((_) => _loadUnreadNotificationsCount());
            },
          ),
          const SizedBox(height: 16),
           _buildDashboardTile(
            context,
            icon: Icons.workspace_premium_outlined,
            title: 'Accès Premium',
            onTap: () {
              Navigator.of(context).push(_slideTransition(const PremiumScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.help_outline,
            title: "Guide d'utilisation",
            onTap: () {
              Navigator.of(context).push(_slideTransition(const GuideScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showExitDialog(context);
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Quitter'),
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
              Expanded(child: Text('Confirmation')),
            ],
          ),
          content: const Text('Voulez-vous vraiment quitter l\'application ?'),
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
                exit(0); // Ferme l'application complètement
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

  Widget _buildDashboardTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, int? badgeCount}) {
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
              if (badgeCount != null && badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
