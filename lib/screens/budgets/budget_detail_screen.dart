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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.budget.name),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Aperçu", icon: Icon(Icons.payments_rounded, size: 20)),
              Tab(text: "Bilan & Historique", icon: Icon(Icons.history_rounded, size: 20)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _transactions.isNotEmpty ? _exportToPdf : null,
          backgroundColor: _transactions.isNotEmpty ? Colors.green : Colors.grey,
          tooltip: 'Exporter en PDF',
          child: const Icon(Icons.picture_as_pdf, color: Colors.white),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    double progress = (widget.budget.spentAmount / widget.budget.amount).clamp(0.0, 1.0);
    double remaining = widget.budget.amount - widget.budget.spentAmount;
    Color progressColor = progress > 0.8 ? Colors.red : (progress > 1 ? Colors.orange : Colors.green);

    final duration = widget.budget.endDate.difference(widget.budget.startDate).inDays;
    final remainingDays = widget.budget.endDate.difference(DateTime.now()).inDays;
    final formattedStartDate = DateFormat('dd/MM/yyyy').format(widget.budget.startDate);
    final formattedEndDate = DateFormat('dd/MM/yyyy').format(widget.budget.endDate);
    final daysLeft = (remainingDays >= 0) ? remainingDays : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildProgressCircle(progress, progressColor)),
          const SizedBox(height: 32),
          _buildInfoCard(formattedStartDate, formattedEndDate, duration, daysLeft),
          const SizedBox(height: 20),
          _buildSummaryCard(remaining),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              "Transactions de ce budget",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          _transactions.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Aucune transaction pour ce budget.")))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) => _buildTransactionItem(_transactions[index]),
                ),
          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  Widget _buildProgressCircle(double progress, Color progressColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SizedBox(
        height: 180,
        width: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              strokeCap: StrokeCap.round,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: progressColor),
                  ),
                  Text(
                    progress > 1 ? 'Dépassé' : 'Utilisé',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String start, String end, int duration, int daysLeft) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.category_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catégorie', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      Text(widget.budget.categoryName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRowWithIcon(Icons.calendar_today_rounded, 'Date de début', start),
            const SizedBox(height: 16),
            _buildInfoRowWithIcon(Icons.event_rounded, 'Date de fin', end),
            const SizedBox(height: 16),
            _buildInfoRowWithIcon(Icons.timer_rounded, 'Durée totale', '$duration jours'),
            const SizedBox(height: 16),
            _buildInfoRowWithIcon(Icons.hourglass_bottom_rounded, 'Temps restant', daysLeft > 1 ? '$daysLeft jours' : '$daysLeft jour'),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Statut du budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        _isActive ? 'Le budget est actuellement actif' : 'Le budget est actuellement inactif',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: _toggleStatus,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildSummaryCard(double remaining) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSummaryRow('Budget total', '${_formatAmount(widget.budget.amount)} FCFA', Colors.blue.shade700),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            _buildSummaryRow('Montant dépensé', '${_formatAmount(widget.budget.spentAmount)} FCFA', Colors.orange.shade700),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            _buildSummaryRow(
              remaining >= 0 ? 'Montant restant' : 'Dépassement',
              '${_formatAmount(remaining.abs())} FCFA',
              remaining >= 0 ? Colors.green.shade700 : Colors.red.shade700,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Map<String, List<TransactionWithDetails>> _groupTransactionsByMonth(List<TransactionWithDetails> transactions) {
    Map<String, List<TransactionWithDetails>> groups = {};
    for (var t in transactions) {
      String key = DateFormat('MMMM yyyy', 'fr_FR').format(t.date);
      key = key[0].toUpperCase() + key.substring(1);
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(t);
    }
    return groups;
  }

  Widget _buildHistoryTab() {
    double totalSpent = _transactions.fold(0, (sum, item) => sum + item.amount);
    final groupedTransactions = _groupTransactionsByMonth(_transactions);
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Somme totale des dépenses",
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "${_formatAmount(totalSpent)} FCFA",
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                "pour le budget ${widget.budget.name}",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Récapitulatif mensuel",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Text("${_transactions.length} écriture(s)", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    String monthName = groupedTransactions.keys.elementAt(index);
                    List<TransactionWithDetails> monthTransactions = groupedTransactions[monthName]!;
                    return _buildMonthSection(monthName, monthTransactions);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMonthSection(String monthName, List<TransactionWithDetails> transactions) {
    double monthTotal = transactions.fold(0, (sum, t) => sum + t.amount);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                  ),
                  Text(
                    "${transactions.length} transaction${transactions.length > 1 ? 's' : ''}",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              Text(
                "${_formatAmount(monthTotal)} FCFA",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1),
              ),
              itemBuilder: (context, index) {
                return _buildSimpleTransactionRow(transactions[index]);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTransactionRow(TransactionWithDetails transaction) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.red.shade700 : Colors.green.shade700;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
      ),
      title: Text(
        transaction.description ?? transaction.categoryName ?? 'Transaction',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        "${transaction.accountName ?? 'Compte'} • ${DateFormat('dd MMM', 'fr_FR').format(transaction.date)}",
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Text(
        "${isExpense ? '-' : '+'} ${_formatAmount(transaction.amount)}",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucune transaction enregistrée", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionWithDetails transaction) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.red.shade700 : Colors.green.shade700;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 22),
        ),
        title: Text(
          transaction.description ?? transaction.categoryName ?? 'Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${transaction.accountName ?? 'Compte'} • ${DateFormat('dd MMM yyyy', 'fr_FR').format(transaction.date)}",
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        trailing: Text(
          "${isExpense ? '-' : '+'} ${_formatAmount(transaction.amount)}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ),
    );
  }
}


