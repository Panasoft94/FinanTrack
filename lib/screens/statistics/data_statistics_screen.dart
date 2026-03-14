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

  final List<Color> _colorList = const [
    Color(0xFF6366F1), // Indigo
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF43F5E), // Rose
  ];

  @override
  void initState() {
    super.initState();
    _statsFuture = DbHelper.getDashboardStatistics();
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
  }

  Color _getCategoryColor(String categoryName) {
    final index = categoryName.hashCode.abs() % _colorList.length;
    return _colorList[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analyses & Statistiques', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
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

          final sortedEntries = expenseData.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // Tri décroissant pour la pertinence
          final sortedExpenseData = Map<String, double>.fromEntries(sortedEntries);
          final double totalExpense = expenseData.values.fold(0.0, (sum, item) => sum + item);

          final chartColorList = sortedExpenseData.keys.map((name) => _getCategoryColor(name)).toList();

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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Résumé des comptes"),
                _buildAccountsSummaryCard(accounts),
                const SizedBox(height: 24),
                _buildSectionTitle("Indicateurs clés"),
                _buildStatsGrid(stats),
                const SizedBox(height: 32),
                if (sortedExpenseData.isNotEmpty) ...[
                  _buildSectionTitle("Répartition des dépenses"),
                  _buildPieChartCard(sortedExpenseData, chartColorList, totalExpense),
                ],
                const SizedBox(height: 32),
                if (expenseTrendSpots.isNotEmpty) ...[
                  _buildSectionTitle("Évolution des dépenses"),
                  _buildTrendCard(expenseTrendSpots),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildAccountsSummaryCard(List<dynamic> accounts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (accounts.isEmpty)
              const Text("Aucun compte trouvé.")
            else
              ...accounts.asMap().entries.map((entry) {
                final index = entry.key;
                final account = entry.value;
                return Column(
                  children: [
                    if (index > 0) Divider(color: Colors.grey[100], height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              account[DbHelper.ACCOUNT_NAME],
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ],
                        ),
                        Text(
                          '${_formatAmount(account[DbHelper.ACCOUNT_BALANCE] as double)} FCFA',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                );
              }),
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
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('Solde Total', '${_formatAmount(stats['totalBalance'] as double)} FCFA', Icons.account_balance_wallet, Colors.indigo),
        _buildStatCard('Comptes', stats['accountsCount'].toString(), Icons.credit_card, Colors.orange),
        _buildStatCard('Transactions', stats['transactionsCount'].toString(), Icons.swap_horiz, Colors.purple),
        _buildStatCard('Budgets Actifs', stats['activeBudgetsCount'].toString(), Icons.inventory_2, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, double> data, List<Color> colors, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          pie.PieChart(
            dataMap: data,
            chartRadius: MediaQuery.of(context).size.width / 2.8,
            legendOptions: const pie.LegendOptions(showLegends: false),
            chartValuesOptions: const pie.ChartValuesOptions(
              showChartValueBackground: false,
              showChartValues: true,
              showChartValuesInPercentage: true,
              showChartValuesOutside: true,
              decimalPlaces: 1,
              chartValueStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            colorList: colors,
            chartType: pie.ChartType.ring,
            ringStrokeWidth: 32,
            centerTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _buildCustomLegend(data, total),
        ],
      ),
    );
  }

  Widget _buildTrendCard(List<FlSpot> spots) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Colors.redAccent, Colors.orangeAccent]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true, 
                      gradient: LinearGradient(
                        colors: [Colors.redAccent.withOpacity(0.2), Colors.redAccent.withOpacity(0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                "Tendance quotidienne sur les 30 derniers jours",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomLegend(Map<String, double> data, double total) {
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: data.entries.toList().map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = _getCategoryColor(entry.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatAmount(entry.value)} FCFA',
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
