import 'package:budget/screens/database/db_helper.dart';
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
    // Utilisation de NumberFormat pour ajouter les séparateurs de milliers
    // Le format 'fr_FR' utilise l'espace comme séparateur
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
      isScrollControlled: true, // Permet au BottomSheet d'utiliser toute la hauteur
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SingleChildScrollView( // Ajout de SingleChildScrollView pour le scrolling
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Conserve mainAxisSize.min
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
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red.shade700,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche pour le titre
          children: [
            const Text(
              'Dépenses Totales',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10), // Séparateur vertical
            Align( // Utiliser Align pour pousser le montant à droite
              alignment: Alignment.centerRight,
              child: Text(
                '${_formatAmount(total)} FCFA',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses mensuelles'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
            children: [
              _buildTotalExpensesCard(totalExpenses),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Text("  Détails par mois  ", style: TextStyle(color: Colors.grey)),
                    Expanded(child: Divider())
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  // Le padding en bas (16 + 56 + 16 (hauteur standard FAB + padding)) est ajouté
                  // pour s'assurer que le dernier élément de la liste n'est pas caché par le FAB.
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: _loadedData!.length,
                  itemBuilder: (context, index) {
                    final item = _loadedData![index];
                    final month = item['month'] as String;
                    final total = (item['total'] as num).toDouble();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Le mois en haut comme titre de bloc
                            Text(
                              _formatMonth(month),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            // La ligne de détails
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.calendar_month, color: Colors.red, size: 30),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "Total des dépenses",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                ),
                                Text(
                                  "${_formatAmount(total)} FCFA",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPieChart,
        label: const Text('Graphique'),
        icon: const Icon(Icons.pie_chart),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}
