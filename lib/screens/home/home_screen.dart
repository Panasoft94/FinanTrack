import 'package:budget/screens/budgets/budgets_screen.dart';
import 'package:budget/screens/dashboard/dashboard_screen.dart';
import 'package:budget/screens/documents/documents_screen.dart';
import 'package:budget/screens/reports/reports_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.monetization_on),
            SizedBox(width: 8),
            Text('FinanTrack'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Budgets'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Rapports'),
            Tab(icon: Icon(Icons.file_copy), text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          DashboardScreen(),
          BudgetsScreen(),
          ReportsScreen(),
          DocumentsScreen(),
        ],
      ),
    );
  }
}
