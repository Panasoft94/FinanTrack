import 'package:budget/screens/budgets/budgets_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';

class BudgetDetailScreen extends StatefulWidget {
  final BudgetWithDetails budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.budget.status == 1;
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

  @override
  Widget build(BuildContext context) {
    double progress = (widget.budget.spentAmount / widget.budget.amount).clamp(0.0, 1.0);
    double remaining = widget.budget.amount - widget.budget.spentAmount;
    Color progressColor = progress > 0.8 ? Colors.red : Colors.green;
    if (progress > 1) progressColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget.name),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.budget.categoryName ?? 'Budget',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Switch(
                            value: _isActive,
                            onChanged: _toggleStatus,
                            activeTrackColor: Colors.green.shade200,
                            activeColor: Colors.green,
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
                          _buildDetailRow('Budget total:', '${widget.budget.amount.toStringAsFixed(2)} €', context),
                          const Divider(height: 30),
                          _buildDetailRow('Montant dépensé:', '${widget.budget.spentAmount.toStringAsFixed(2)} €', context, valueColor: Colors.orange[800]),
                          const Divider(height: 30),
                          _buildDetailRow(
                            remaining >= 0 ? 'Montant restant:' : 'Dépassement:',
                            '${remaining.abs().toStringAsFixed(2)} €',
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
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DbHelper.getTransactionsForBudget(widget.budget.categoryId!, widget.budget.startDate.toIso8601String(), widget.budget.endDate.toIso8601String()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Aucune transaction pour ce budget.")));
                }
                final transactions = snapshot.data!.map((map) => TransactionWithDetails.fromMap(map)).toList();
                return _buildTransactionList(transactions);
              },
            ),
          ],
        ),
      ),
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
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction.categoryColor?.withOpacity(0.2),
              child: Icon(transaction.categoryIcon, color: transaction.categoryColor, size: 24),
            ),
            title: Text(transaction.description ?? transaction.categoryName ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(transaction.accountName ?? 'Compte non spécifié', style: TextStyle(color: Colors.grey[600])),
            trailing: Text(
              '- ${transaction.amount.toStringAsFixed(2)} €',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red[700]),
            ),
          ),
        );
      },
    );
  }
}
