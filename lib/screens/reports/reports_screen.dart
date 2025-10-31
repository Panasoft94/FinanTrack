import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Future<List<TransactionWithDetails>>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  void _loadReportData() {
    setState(() {
      _reportFuture = DbHelper.getTransactionsWithDetailsInRange(
        _startDate.toIso8601String(),
        _endDate.toIso8601String(),
      ).then((maps) => maps.map((map) => TransactionWithDetails.fromMap(map)).toList());
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020), 
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          // Correction: S'assure d'inclure toute la journée de fin
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
        _loadReportData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.assessment), SizedBox(width: 8), Text('Rapports')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterSection(context),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<TransactionWithDetails>>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucune transaction pour cette période."));
                  }
                  return _buildReportContent(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDateSelector('Du', _startDate, () => _selectDate(context, true)),
            const Icon(Icons.arrow_forward, color: Colors.grey),
            _buildDateSelector('Au', _endDate, () => _selectDate(context, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(DateFormat('d MMM yyyy', 'fr_FR').format(date))]),
    );
  }

  Widget _buildReportContent(List<TransactionWithDetails> transactions) {
    final double totalIncome = transactions.where((t) => t.type == 'income').fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpense = transactions.where((t) => t.type == 'expense').fold(0.0, (sum, item) => sum + item.amount);
    final double netResult = totalIncome - totalExpense;

    final Map<String, double> expenseByCategory = {};
    for (var t in transactions.where((t) => t.type == 'expense')) {
      final categoryName = t.categoryName ?? 'Non classé';
      expenseByCategory[categoryName] = (expenseByCategory[categoryName] ?? 0) + t.amount;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryCard(totalIncome, totalExpense, netResult),
          const SizedBox(height: 20),
          if (expenseByCategory.isNotEmpty)
            PieChart(
              dataMap: expenseByCategory,
              animationDuration: const Duration(milliseconds: 800),
              chartLegendSpacing: 32,
              chartRadius: MediaQuery.of(context).size.width / 3.2,
              initialAngleInDegree: 0,
              chartType: ChartType.ring,
              ringStrokeWidth: 32,
              legendOptions: const LegendOptions(showLegendsInRow: true, legendPosition: LegendPosition.bottom, showLegends: true, legendTextStyle: TextStyle(fontWeight: FontWeight.bold)),
              chartValuesOptions: const ChartValuesOptions(showChartValueBackground: true, showChartValues: true, showChartValuesInPercentage: true, decimalPlaces: 1),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double income, double expense, double net) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn('Total Revenus', income, Colors.green[700]!),
            _buildSummaryColumn('Total Dépenses', expense, Colors.red[700]!),
            _buildSummaryColumn('Solde Net', net, net >= 0 ? Colors.blue[800]! : Colors.red[700]!),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
        const SizedBox(height: 5),
        Text('${amount.toStringAsFixed(2)} €', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }
}
