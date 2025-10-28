import 'package:flutter/material.dart';
import './budgets_screen.dart'; // Importer pour utiliser la classe Budget

class BudgetDetailScreen extends StatelessWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    double progress = (budget.spentAmount / budget.totalAmount).clamp(0.0, 1.0);
    double remaining = budget.totalAmount - budget.spentAmount;
    Color progressColor = progress > 0.8 ? Colors.red : Colors.green;
    if (progress > 1) progressColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(budget.icon),
            const SizedBox(width: 8),
            Text(budget.category),
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
            _buildDetailRow('Budget total:', '${budget.totalAmount.toStringAsFixed(2)} €', context),
            const Divider(height: 30),
            _buildDetailRow('Montant dépensé:', '${budget.spentAmount.toStringAsFixed(2)} €', context, valueColor: Colors.orange[800]),
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
