import 'package:budget/models/transactions_model.dart';
import 'package:budget/screens/budgets/budgets_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BudgetDetailScreen extends StatefulWidget {
  final BudgetWithDetails budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late bool _isActive;
  List<TransactionWithDetails> _transactions = [];

  @override
  void initState() {
    super.initState();
    _isActive = widget.budget.status == 1;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final maps = await DbHelper.getTransactionsForBudget(
      widget.budget.categoryId!,
      widget.budget.startDate.toIso8601String(),
      widget.budget.endDate.toIso8601String(),
    );
    if (mounted) {
      setState(() {
        _transactions = maps.map((map) => TransactionWithDetails.fromMap(map)).toList();
      });
    }
  }
  
  String _formatAmount(double amount) {
    // Utilisation de NumberFormat pour ajouter les séparateurs de milliers
    // Le format 'fr_FR' utilise l'espace comme séparateur
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
  }

  void _toggleStatus(bool newValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: Row(children: [
          Icon(newValue ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: newValue ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(newValue ? 'Activer le budget' : 'Désactiver le budget'))
        ]),
        content: Text('Voulez-vous vraiment ${newValue ? "activer" : "désactiver"} ce budget ?'),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          OutlinedButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[800], side: BorderSide(color: Colors.grey[400]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          ElevatedButton(
            child: Text(newValue ? 'Activer' : 'Désactiver'),
            onPressed: () async {
              setState(() {
                _isActive = newValue;
              });
              widget.budget.status = _isActive ? 1 : 0;
              await DbHelper.updateBudget(widget.budget.toMap());
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isActive ? 'Budget activé avec succès.' : 'Budget désactivé avec succès.'),
                    backgroundColor: _isActive ? Colors.green[700] : Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: newValue ? Colors.green : Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    final double totalBudget = widget.budget.amount;
    final double spentAmount = widget.budget.spentAmount;
    final double remainingAmount = totalBudget - spentAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        footer: (pw.Context context) {
          final start = DateFormat('d MMM', 'fr_FR').format(widget.budget.startDate);
          final end = DateFormat('d MMM yyyy', 'fr_FR').format(widget.budget.endDate);
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Rapport du budget du $start au $end',
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
                pw.Text('Rapport du Budget: ${widget.budget.name}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.now())),
              ],
            ),
          ),
          pw.Text('Période du ${DateFormat('d/M/y').format(widget.budget.startDate)} au ${DateFormat('d/M/y').format(widget.budget.endDate)}'),
          pw.Divider(height: 20),
          pw.Header(level: 1, text: 'Résumé du Budget'),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildPdfSummary('Budget Total', totalBudget, PdfColors.blue),
              _buildPdfSummary('Montant Dépensé', spentAmount, PdfColors.orange),
              _buildPdfSummary(
                remainingAmount >= 0 ? 'Montant Restant' : 'Dépassement',
                remainingAmount.abs(),
                remainingAmount >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Header(level: 1, text: 'Détail des Transactions'),
          pw.Table.fromTextArray(
            headers: ['Date', 'Description', 'Compte', 'Montant'],
            data: _transactions.map((t) => [
              DateFormat('d/M/y').format(t.date),
              t.description ?? 'N/A',
              t.accountName ?? 'N/A',
              '-${_formatAmount(t.amount)} FCFA',
            ]).toList(),
          ),
        ],
      ),
    );

    final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
    final budgetName = widget.budget.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Rapport_Budget_${budgetName}_$dateStr.pdf');
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
    double progress = (widget.budget.spentAmount / widget.budget.amount).clamp(0.0, 1.0);
    double remaining = widget.budget.amount - widget.budget.spentAmount;
    Color progressColor = progress > 0.8 ? Colors.red : Colors.green;
    if (progress > 1) progressColor = Colors.orange;

    final duration = widget.budget.endDate.difference(widget.budget.startDate).inDays;
    final remainingDays = widget.budget.endDate.difference(DateTime.now()).inDays;
    final formattedStartDate = DateFormat('dd/MM/yyyy').format(widget.budget.startDate);
    final formattedEndDate = DateFormat('dd/MM/yyyy').format(widget.budget.endDate);
    final daysLeft = (remainingDays >= 0) ? remainingDays : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget.name),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _transactions.isNotEmpty ? _exportToPdf : null,
        backgroundColor: _transactions.isNotEmpty ? Colors.green : Colors.grey,
        tooltip: 'Exporter en PDF',
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 15,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 2,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                              children: [
                                const TextSpan(text: 'Catégorie: '),
                                TextSpan(
                                  text: widget.budget.categoryName ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow('Date de début:', formattedStartDate),
                          const SizedBox(height: 8),
                          _buildInfoRow('Date de fin:', formattedEndDate),
                          const SizedBox(height: 8),
                          _buildInfoRow('Durée:', '$duration jours'),
                          const SizedBox(height: 8),
                          _buildInfoRow('Jours restants:', daysLeft > 1 ? '$daysLeft jours' : '$daysLeft jour'),
                          const Divider(height: 25, thickness: 1),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Statut',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isActive ? 'Le budget est actuellement actif.' : 'Le budget est actuellement inactif.',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: _toggleStatus,
                                activeTrackColor: Colors.green.shade200,
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow('Budget total:', '${_formatAmount(widget.budget.amount)} FCFA', context),
                          const Divider(height: 30),
                          _buildDetailRow('Montant dépensé:', '${_formatAmount(widget.budget.spentAmount)} FCFA', context, valueColor: Colors.orange[800]),
                          const Divider(height: 30),
                          _buildDetailRow(
                            remaining >= 0 ? 'Montant restant:' : 'Dépassement:',
                            '${_formatAmount(remaining.abs())} FCFA',
                            context,
                            valueColor: remaining >= 0 ? Colors.green[800] : Colors.red[800],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text("Transactions de ce budget", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
            // Updated this section to use the state variable _transactions
            _transactions.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Aucune transaction pour ce budget.")))
                : _buildTransactionList(_transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value, BuildContext context, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<TransactionWithDetails> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isExpense = transaction.type == 'expense';
        final color = isExpense ? Colors.red[700]! : Colors.green[700]!;
        final icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(transaction.description ?? transaction.categoryName ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.accountName ?? 'Compte non spécifié', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy', 'fr_FR').format(transaction.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Text(
              '- ${_formatAmount(transaction.amount)} FCFA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ),
        );
      },
    );
  }
}
