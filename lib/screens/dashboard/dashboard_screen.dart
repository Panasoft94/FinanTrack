import 'package:budget/screens/expense_category/expense_category_screen.dart';
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
              Navigator.of(context).push(_createFadeRoute(const TransactionsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.settings,
            title: 'Paramètres',
            onTap: () {
              Navigator.of(context).push(_createFadeRoute(const SettingsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.category,
            title: 'Catégorie depense',
            onTap: () {
              Navigator.of(context).push(_createFadeRoute(const ExpenseCategoryScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.analytics,
            title: 'Statistique des données',
            onTap: () {
              Navigator.of(context).push(_createFadeRoute(const DataStatisticsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.of(context).push(_createFadeRoute(const NotificationsScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (Route<dynamic> route) => false,
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.exit_to_app),
        tooltip: 'Quitter',
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
