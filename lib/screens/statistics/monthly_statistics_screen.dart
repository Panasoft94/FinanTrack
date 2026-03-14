import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/statistics/monthly_transactions_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart' as pie;

class MonthlyStatisticsScreen extends StatefulWidget {
  const MonthlyStatisticsScreen({super.key});

  @override
  State<MonthlyStatisticsScreen> createState() => _MonthlyStatisticsScreenState();
}

class _MonthlyStatisticsScreenState extends State<MonthlyStatisticsScreen> {
  late Future<List<Map<String, dynamic>>> _monthlyExpensesFuture;
  List<Map<String, dynamic>>? _loadedData;

  @override
  void initState() {
    super.initState();
    _monthlyExpensesFuture = DbHelper.getExpensesByMonth();
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
  }

  String _formatMonth(String monthStr) {
    try {
      final date = DateTime.parse('$monthStr-01');
      String formatted = DateFormat('MMMM yyyy', 'fr_FR').format(date);
      if (formatted.isNotEmpty) {
        return formatted[0].toUpperCase() + formatted.substring(1);
      }
      return formatted;
    } catch (e) {
      return monthStr;
    }
  }

  void _showPieChart() {
    if (_loadedData == null || _loadedData!.isEmpty) return;

    Map<String, double> dataMap = {};
    for (var item in _loadedData!) {
      dataMap[_formatMonth(item['month'])] = (item['total'] as num).toDouble();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Répartition des dépenses par mois',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                pie.PieChart(
                  dataMap: dataMap,
                  animationDuration: const Duration(milliseconds: 800),
                  chartLegendSpacing: 32,
                  chartRadius: MediaQuery.of(context).size.width / 2.8,
                  colorList: const [
                    Colors.redAccent,
                    Colors.blueAccent,
                    Colors.orangeAccent,
                    Colors.greenAccent,
                    Colors.purpleAccent,
                    Colors.cyanAccent,
                    Colors.amberAccent,
                  ],
                  initialAngleInDegree: 0,
                  chartType: pie.ChartType.disc,
                  ringStrokeWidth: 32,
                  legendOptions: const pie.LegendOptions(
                    showLegendsInRow: false,
                    legendPosition: pie.LegendPosition.right,
                    showLegends: true,
                    legendTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  chartValuesOptions: const pie.ChartValuesOptions(
                    showChartValueBackground: true,
                    showChartValues: true,
                    showChartValuesInPercentage: true,
                    showChartValuesOutside: false,
                    decimalPlaces: 1,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalExpensesCard(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade800, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.account_balance_wallet,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.trending_down, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Dépenses Totales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${_formatAmount(total)} FCFA',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cumul sur tous les mois enregistrés',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Statistiques',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _monthlyExpensesFuture = DbHelper.getExpensesByMonth();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _monthlyExpensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucune donnée de dépense.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          _loadedData = snapshot.data!;
          final double totalExpenses = _loadedData!.fold(0.0, (sum, item) => sum + (item['total'] as num).toDouble());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalExpensesCard(totalExpenses),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  "Historique Mensuel",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _loadedData!.length,
                  itemBuilder: (context, index) {
                    final item = _loadedData![index];
                    final month = item['month'] as String;
                    final total = (item['total'] as num).toDouble();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MonthlyTransactionsDetailScreen(
                                  month: month,
                                  monthName: _formatMonth(month),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.red.shade700,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatMonth(month),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Total des transactions",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${_formatAmount(total)}",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    const Text(
                                      "FCFA",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPieChart,
        elevation: 4,
        highlightElevation: 8,
        label: const Text(
          'Voir l\'Analyse',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        icon: const Icon(Icons.donut_large_rounded),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
