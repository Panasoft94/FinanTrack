import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<TransactionWithDetails> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    final maps = await DbHelper.getTransactionsWithDetailsInRange(
      _startDate.toIso8601String(),
      _endDate.toIso8601String(),
    );

    if (mounted) {
      setState(() {
        _transactions = maps.map((map) => TransactionWithDetails.fromMap(map)).toList();
        _isLoading = false;
      });
    }
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
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
        _loadReportData();
      });
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    final double totalIncome = _transactions.where((t) => t.type == 'income').fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpense = _transactions.where((t) => t.type == 'expense').fold(0.0, (sum, item) => sum + item.amount);
    final double netResult = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Rapport Financier', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.now())),
              ],
            ),
          ),
          pw.Text('Période du ${DateFormat('d/M/y').format(_startDate)} au ${DateFormat('d/M/y').format(_endDate)}'),
          pw.Divider(height: 20),
          pw.Header(level: 1, text: 'Résumé'),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildPdfSummary('Total Revenus', totalIncome, PdfColors.green),
              _buildPdfSummary('Total Dépenses', totalExpense, PdfColors.red),
              _buildPdfSummary('Solde Net', netResult, netResult >= 0 ? PdfColors.blue : PdfColors.red),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Header(level: 1, text: 'Détail des Transactions'),
          pw.Table.fromTextArray(
            headers: ['Date', 'Description', 'Catégorie', 'Compte', 'Montant'],
            data: _transactions.map((t) => [
              DateFormat('d/M/y').format(t.date),
              t.description ?? 'N/A',
              t.categoryName ?? 'N/A',
              t.accountName ?? 'N/A',
              '${t.type == 'expense' ? '-' : '+'}${t.amount.toStringAsFixed(2)} €',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildPdfSummary(String title, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 5),
        pw.Text('${amount.toStringAsFixed(2)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                      ? const Center(child: Text("Aucune transaction pour cette période."))
                      : _buildReportContent(_transactions),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _transactions.isNotEmpty ? _exportToPdf : null,
        backgroundColor: _transactions.isNotEmpty ? Colors.green : Colors.grey,
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
        tooltip: 'Exporter en PDF',
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
    return Column(
      children: [
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummaryRow('Total Revenus', income, Colors.green[700]!),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummaryRow('Total Dépenses', expense, Colors.red[700]!),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummaryRow('Solde Net', net, net >= 0 ? Colors.blue[800]! : Colors.red[700]!),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String title, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
        Text('${amount.toStringAsFixed(2)} FCFA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }
}
