import 'package:budget/screens/budgets/budget_detail_screen.dart';
import 'package:flutter/material.dart';

// Modèle simple pour représenter un budget
class Budget {
  String category;
  final IconData icon;
  double totalAmount;
  double spentAmount;

  Budget({
    required this.category,
    required this.icon,
    required this.totalAmount,
    this.spentAmount = 0.0,
  });
}

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  // Liste de budgets (simulée)
  final List<Budget> _budgets = [
    Budget(category: 'Nourriture', icon: Icons.fastfood, totalAmount: 500, spentAmount: 250.50),
    Budget(category: 'Transport', icon: Icons.directions_car, totalAmount: 200, spentAmount: 150),
    Budget(category: 'Loisirs', icon: Icons.sports_esports, totalAmount: 300, spentAmount: 310),
  ];

  void _deleteBudget(Budget budget) {
    setState(() {
      _budgets.remove(budget);
    });
  }
  
  PageRouteBuilder _slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
  }

  void _showAddOrEditBudgetSheet({Budget? budgetToEdit}) {
    final isEditing = budgetToEdit != null;
    final categoryController = TextEditingController(text: isEditing ? budgetToEdit.category : '');
    final amountController = TextEditingController(text: isEditing ? budgetToEdit.totalAmount.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEditing ? 'Modifier le Budget' : 'Nouveau Budget', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant Total',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
                onPressed: () {
                  final category = categoryController.text;
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (category.isNotEmpty && amount > 0) {
                    setState(() {
                      if (isEditing) {
                        budgetToEdit.category = category;
                        budgetToEdit.totalAmount = amount;
                      } else {
                        _budgets.add(Budget(category: category, icon: Icons.wallet_giftcard, totalAmount: amount));
                      }
                    });
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteDialog(Budget budget) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(child: Text('Supprimer le budget')),
            ],
          ),
          content: Text('Êtes-vous sûr de vouloir supprimer le budget "${budget.category}" ? Cette action est irréversible.'),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[800],
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Supprimer'),
              onPressed: () {
                _deleteBudget(budget);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'Aucun budget pour le moment',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Cliquez sur le bouton + pour commencer.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _budgets.length,
              itemBuilder: (context, index) {
                return _buildBudgetCard(_budgets[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOrEditBudgetSheet,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un budget',
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    double progress = (budget.spentAmount / budget.totalAmount).clamp(0.0, 1.0);
    double remaining = budget.totalAmount - budget.spentAmount;
    Color progressColor = progress > 0.8 ? Colors.red : Colors.green;
    if (progress > 1) progressColor = Colors.orange;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(_slideTransition(BudgetDetailScreen(budget: budget)));
        },
        onLongPress: () {
          _showDeleteDialog(budget);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(budget.icon, color: Theme.of(context).primaryColor, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Text(budget.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Text(
                    '${budget.spentAmount.toStringAsFixed(2)} € / ${budget.totalAmount.toStringAsFixed(2)} €',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showAddOrEditBudgetSheet(budgetToEdit: budget),
                    splashRadius: 20,
                    color: Colors.grey[600],
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  remaining >= 0 
                    ? 'Restant : ${remaining.toStringAsFixed(2)} €'
                    : 'Dépassement : ${(-remaining).toStringAsFixed(2)} €',
                  style: TextStyle(fontWeight: FontWeight.bold, color: remaining >= 0 ? Colors.black54 : Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
