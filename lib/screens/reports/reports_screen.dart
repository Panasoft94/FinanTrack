import 'package:budget/models/transactions_model.dart';
import 'package:budget/screens/database/db_helper.dart';
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

  final List<Color> _colorList = const [
    Color(0xFF8A2BE2), // BlueViolet
    Color(0xFF00BFFF), // DeepSkyBlue
    Color(0xFF7FFFD4), // Aquamarine
    Color(0xFF3CB371), // MediumSeaGreen
    Color(0xFFFDD835), // Vivid Yellow
    Color(0xFFFFB74D), // Light Orange
    Color(0xFFFF7043), // Vivid Orange
    Color(0xFFEC407A), // Vivid Pink
    Color(0xFF7E57C2), // Deep Purple
  ];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  String _formatAmount(double amount) {
    // Utilisation de NumberFormat pour ajouter les séparateurs de milliers
    // Le format 'fr_FR' utilise l'espace comme séparateur
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
  }

  Color _getCategoryColor(String categoryName) {
    final index = categoryName.hashCode.abs() % _colorList.length;
    return _colorList[index];
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
        footer: (pw.Context context) {
          final start = DateFormat('d MMM', 'fr_FR').format(_startDate);
          final end = DateFormat('d MMM yyyy', 'fr_FR').format(_endDate);
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Rapport financier du $start au $end',
                style: pw.TextStyle(color: PdfColors.grey, fontStyle: pw.FontStyle.italic),
              ),
              pw.Text(
                'Page ${context.pageNumber} sur ${context.pagesCount}',
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey),
              ),
            ],
          );
        },
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
              '${t.type == 'expense' ? '-' : '+'}${_formatAmount(t.amount)} FCFA',
            ]).toList(),
          ),
        ],
      ),
    );

    final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Rapport_financier_du_$dateStr.pdf');
  }

  pw.Widget _buildPdfSummary(String title, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 5),
        pw.Text('${_formatAmount(amount)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_rounded),
            SizedBox(width: 12),
            Text(
              'Rapports Financiers',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            )
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterSection(context),
                  const SizedBox(height: 24),
                  if (_transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80.0),
                        child: Column(
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "Aucune transaction pour cette période.",
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildReportContent(_transactions),
                  const SizedBox(height: 80), // Espace pour le FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _transactions.isNotEmpty ? _exportToPdf : null,
        backgroundColor: _transactions.isNotEmpty ? Colors.green : Colors.grey[400],
        elevation: 4,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
        label: const Text('EXPORTER PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        tooltip: 'Exporter en PDF',
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Période du rapport',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Du',
                  _startDate,
                  () => _selectDate(context, true),
                  Icons.calendar_today_rounded,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.green.withOpacity(0.5), size: 20),
              ),
              Expanded(
                child: _buildDateSelector(
                  'Au',
                  _endDate,
                  () => _selectDate(context, false),
                  Icons.event_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap, IconData icon) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(
                    DateFormat('d MMM yyyy', 'fr_FR').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

    final sortedEntries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Tri décroissant pour le graphique
    final sortedExpenseByCategory = Map<String, double>.fromEntries(sortedEntries);

    final chartColorList = sortedExpenseByCategory.keys.map((name) => _getCategoryColor(name)).toList();

    return Column(
      children: [
        _buildSummaryGrid(totalIncome, totalExpense, netResult),
        const SizedBox(height: 32),
        if (expenseByCategory.isNotEmpty) ...[
          Text(
            'Répartition des dépenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                PieChart(
                  dataMap: sortedExpenseByCategory,
                  animationDuration: const Duration(milliseconds: 1200),
                  chartLegendSpacing: 32,
                  chartRadius: MediaQuery.of(context).size.width / 2.2,
                  initialAngleInDegree: 0,
                  chartType: ChartType.ring,
                  ringStrokeWidth: 24,
                  colorList: chartColorList.isEmpty ? [Colors.grey] : chartColorList,
                  legendOptions: const LegendOptions(showLegends: false),
                  chartValuesOptions: const ChartValuesOptions(
                    showChartValueBackground: false,
                    showChartValues: true,
                    showChartValuesInPercentage: true,
                    showChartValuesOutside: true,
                    decimalPlaces: 1,
                    chartValueStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
                _buildCustomLegend(sortedExpenseByCategory, totalExpense),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildFooter(),
      ],
    );
  }

  Widget _buildSummaryGrid(double income, double expense, double net) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryItem('Revenus', income, Colors.green, Icons.trending_up_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryItem('Dépenses', expense, Colors.red, Icons.trending_down_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        _buildNetResultItem(net),
      ],
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_formatAmount(amount)} FCFA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetResultItem(double net) {
    final color = net >= 0 ? Colors.blue[700]! : Colors.red[700]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOLDE NET',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatAmount(net)} FCFA',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ],
          ),
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white30, size: 48),
        ],
      ),
    );
  }

  Widget _buildCustomLegend(Map<String, double> data, double total) {
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: data.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = _getCategoryColor(entry.key);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatAmount(entry.value)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    final start = DateFormat('d MMM', 'fr_FR').format(_startDate);
    final end = DateFormat('d MMM yyyy', 'fr_FR').format(_endDate);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
      child: Column(
        children: [
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'Rapport généré le ${DateFormat('d MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now())}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
          ),
          Text(
            'Période couverte : $start - $end',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }
}
