import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyTransactionsDetailScreen extends StatefulWidget {
  final String month;
  final String monthName;

  const MonthlyTransactionsDetailScreen({
    super.key,
    required this.month,
    required this.monthName,
  });

  @override
  State<MonthlyTransactionsDetailScreen> createState() => _MonthlyTransactionsDetailScreenState();
}

class _MonthlyTransactionsDetailScreenState extends State<MonthlyTransactionsDetailScreen> {
  late Future<List<Map<String, dynamic>>> _expensesFuture;
  List<Map<String, dynamic>>? _snapshotData;

  static final List<IconData> availableIcons = [
    Icons.shopping_cart, Icons.fastfood, Icons.directions_car, Icons.movie,
    Icons.house, Icons.work, Icons.savings, Icons.receipt_long,
    Icons.medical_services, Icons.school, Icons.local_gas_station, Icons.phone_android,
    Icons.train, Icons.lightbulb_outline, Icons.pets, Icons.book,
  ];

  @override
  void initState() {
    super.initState();
    _expensesFuture = DbHelper.getExpensesByMonthDetail(widget.month);
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      String formatted = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
      if (formatted.isNotEmpty) {
        return formatted[0].toUpperCase() + formatted.substring(1);
      }
      return formatted;
    } catch (e) {
      return dateStr;
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupExpensesByDate(List<Map<String, dynamic>> expenses) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tx in expenses) {
      String fullDate = tx[DbHelper.TRANSACTION_DATE].toString();
      String dateKey = fullDate.contains('T') ? fullDate.split('T')[0] : fullDate.split(' ')[0];
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(tx);
    }
    return grouped;
  }

  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.blue;
    try {
      if (colorValue is String) {
        if (colorValue.startsWith('#')) {
          return Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
        }
        return Color(int.parse(colorValue));
      } else if (colorValue is int) {
        return Color(colorValue);
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(dynamic iconValue) {
    if (iconValue == null) return Icons.category;
    try {
      String iconString = iconValue.toString();
      int codePoint = int.parse(iconString);
      return availableIcons.firstWhere(
        (icon) => icon.codePoint == codePoint,
        orElse: () => Icons.category,
      );
    } catch (e) {
      return Icons.category;
    }
  }

  Future<void> _exportToPdf() async {
    if (_snapshotData == null || _snapshotData!.isEmpty) return;

    final pdf = pw.Document();
    final double totalExpense = _snapshotData!.fold(0.0, (sum, item) => sum + (item[DbHelper.MONTANT] as num).toDouble());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Rapport des dépenses mensuelles - ${widget.monthName}',
                style: pw.TextStyle(color: PdfColors.grey, fontStyle: pw.FontStyle.italic, fontSize: 10),
              ),
              pw.Text(
                'Page ${context.pageNumber} sur ${context.pagesCount}',
                style: pw.TextStyle(color: PdfColors.grey, fontSize: 10),
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
                pw.Text('FinanTrack - Rapport Mensuel', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                pw.Text(DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Détail des dépenses pour : ${widget.monthName}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Divider(height: 20, thickness: 1, color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total du mois : ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('${_formatAmount(totalExpense)} FCFA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Description', 'Catégorie', 'Compte', 'Montant'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red700),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              4: pw.Alignment.centerRight,
            },
            data: _snapshotData!.map((t) {
              final date = t[DbHelper.TRANSACTION_DATE].toString();
              final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
              return [
                formattedDate,
                t[DbHelper.TRANSACTION_DESCRIPTION] ?? 'N/A',
                t[DbHelper.CATEGORY_NAME] ?? 'N/A',
                t[DbHelper.ACCOUNT_NAME] ?? 'N/A',
                '${_formatAmount((t[DbHelper.MONTANT] as num).toDouble())} FCFA',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Depenses_${widget.monthName.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dépenses : ${widget.monthName}"),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _expensesFuture,
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
                  Icon(Icons.money_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucune dépense pour ce mois.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          _snapshotData = snapshot.data!;
          final groupedExpenses = _groupExpensesByDate(_snapshotData!);
          final sortedDates = groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              String date = sortedDates[index];
              List<Map<String, dynamic>> txs = groupedExpenses[date]!;
              double dailyTotal = txs.fold(0.0, (sum, item) => sum + (item[DbHelper.MONTANT] as num).toDouble());

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "- ${_formatAmount(dailyTotal)} FCFA",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...txs.map((tx) {
                    final categoryName = tx[DbHelper.CATEGORY_NAME] ?? 'Sans catégorie';
                    final categoryColor = _parseColor(tx[DbHelper.CATEGORY_COLOR]);
                    final amount = (tx[DbHelper.MONTANT] as num).toDouble();
                    final description = tx[DbHelper.TRANSACTION_DESCRIPTION] ?? '';
                    final accountName = tx[DbHelper.ACCOUNT_NAME] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconData(tx[DbHelper.CATEGORY_ICON]),
                            color: categoryColor,
                            size: 26,
                          ),
                        ),
                        title: Text(
                          categoryName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  accountName,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          "- ${_formatAmount(amount)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportToPdf,
        label: const Text('Exporter PDF'),
        icon: const Icon(Icons.picture_as_pdf),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
