import 'package:budget/screens/budgets/budgets_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
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

  void _toggleStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: Row(children: [
          Icon(_isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: _isActive ? Colors.red : Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(_isActive ? 'Désactiver le budget' : 'Activer le budget'))
        ]),
        content: Text('Voulez-vous vraiment ${_isActive ? "désactiver" : "activer"} ce budget ?'),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          OutlinedButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[800], side: BorderSide(color: Colors.grey[400]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          ElevatedButton(
            child: Text(_isActive ? 'Désactiver' : 'Activer'),
            onPressed: () async {
              setState(() => _isActive = !_isActive);
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
            style: ElevatedButton.styleFrom(backgroundColor: _isActive ? Colors.red : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.budget.categoryIcon),
            const SizedBox(width: 8),
            Text(widget.budget.categoryName ?? widget.budget.name),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
            const SizedBox(height: 50),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleStatus,
        label: Text(_isActive ? 'Désactiver' : 'Activer'),
        icon: Icon(_isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined),
        backgroundColor: _isActive ? Colors.red[700] : Colors.green[700],
        foregroundColor: Colors.white,
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
}
