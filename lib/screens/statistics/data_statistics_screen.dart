import 'package:budget/screens/database/db_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart' as pie;

class DataStatisticsScreen extends StatefulWidget {
  const DataStatisticsScreen({super.key});

  @override
  State<DataStatisticsScreen> createState() => _DataStatisticsScreenState();
}

class _DataStatisticsScreenState extends State<DataStatisticsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = DbHelper.getDashboardStatistics();
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncate()) {
      return amount.truncate().toString();
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.analytics), SizedBox(width: 8), Text('Statistiques')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune donnée à afficher."));
          }

          final stats = snapshot.data!;
          final List<dynamic> accounts = stats['accountsList'] ?? [];
          final Map<String, double> expenseData = {};
          if (stats['expensesByCategory'] != null) {
            for (var item in (stats['expensesByCategory'] as List)) {
              expenseData[item['name']] = (item['total'] as num?)?.toDouble() ?? 0.0;
            }
          }

          // --- Préparation des données pour le graphique de tendance ---
          final List<FlSpot> expenseTrendSpots = [];
          final trendData = (stats['expenseTrend'] as List<dynamic>?) ?? [];
          final Map<String, double> dailyTotalsFromDb = {
            for (var item in trendData) (item['day'] as String): ((item['total'] as num?)?.toDouble() ?? 0.0)
          };

          for (int i = 0; i < 30; i++) {
            final date = DateTime.now().subtract(Duration(days: 29 - i));
            final dateString = DateFormat('yyyy-MM-dd').format(date);
            final total = dailyTotalsFromDb[dateString] ?? 0.0;
            expenseTrendSpots.add(FlSpot(i.toDouble(), total));
          }
          // --- Fin de la préparation ---

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAccountsSummaryCard(accounts),
                const SizedBox(height: 20),
                _buildStatsGrid(stats),
                const SizedBox(height: 30),
                if (expenseData.isNotEmpty)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text("Dépenses par catégorie", style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 20),
                          pie.PieChart(
                            dataMap: expenseData,
                            chartRadius: MediaQuery.of(context).size.width / 2.5,
                            legendOptions: const pie.LegendOptions(legendPosition: pie.LegendPosition.bottom, showLegendsInRow: true),
                            chartValuesOptions: const pie.ChartValuesOptions(showChartValuesInPercentage: true, decimalPlaces: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                if (expenseTrendSpots.isNotEmpty)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text("Tendance des dépenses (30j)", style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: expenseTrendSpots,
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.3)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                           const SizedBox(height: 10),
                          const Text(
                            "Évolution des dépenses quotidiennes sur les 30 derniers jours.",
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountsSummaryCard(List<dynamic> accounts) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Soldes des comptes", style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            if (accounts.isEmpty)
              const Text("Aucun compte trouvé.")
            else
              ...accounts.map((account) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(account[DbHelper.ACCOUNT_NAME], style: const TextStyle(fontSize: 16)),
                        Text('${_formatAmount(account[DbHelper.ACCOUNT_BALANCE] as double)} FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('Solde Total', '${_formatAmount(stats['totalBalance'] as double)} FCFA', Icons.account_balance_wallet, Colors.blue),
        _buildStatCard('Comptes', stats['accountsCount'].toString(), Icons.credit_card, Colors.orange),
        _buildStatCard('Transactions', stats['transactionsCount'].toString(), Icons.swap_horiz, Colors.purple),
        _buildStatCard('Budgets Actifs', stats['activeBudgetsCount'].toString(), Icons.inventory_2, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
