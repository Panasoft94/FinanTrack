import 'package:budget/screens/budgets/budget_detail_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/expense_category/expense_category_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Modèles de Données ---
class BudgetWithDetails {
  int? id;
  String name;
  double amount;
  DateTime startDate;
  DateTime endDate;
  int? categoryId;
  int status;
  String? categoryName;
  IconData? categoryIcon;
  Color? categoryColor;
  double spentAmount;

  BudgetWithDetails({
    this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.status = 1,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.spentAmount = 0.0,
  });

  factory BudgetWithDetails.fromMap(Map<String, dynamic> map) {
    return BudgetWithDetails(
      id: map[DbHelper.BUDGET_ID],
      name: map[DbHelper.BUDGET_NAME] ?? 'Budget sans nom',
      amount: map[DbHelper.BUDGET_AMOUNT],
      startDate: DateTime.parse(map[DbHelper.BUDGET_START_DATE]),
      endDate: DateTime.parse(map[DbHelper.BUDGET_END_DATE]),
      categoryId: map[DbHelper.CATEGORY_ID],
      status: map[DbHelper.BUDGET_STATUS] ?? 1,
      categoryName: map[DbHelper.CATEGORY_NAME],
      spentAmount: (map['spent_amount'] ?? 0.0).toDouble(),
      categoryIcon: map[DbHelper.CATEGORY_ICON] != null ? IconData(int.parse(map[DbHelper.CATEGORY_ICON]), fontFamily: 'MaterialIcons') : null,
      categoryColor: map[DbHelper.CATEGORY_COLOR] != null ? Color(int.parse(map[DbHelper.CATEGORY_COLOR])) : null,
    );
  }

   Map<String, dynamic> toMap() {
    return {
      DbHelper.BUDGET_ID: id,
      DbHelper.BUDGET_NAME: name,
      DbHelper.BUDGET_AMOUNT: amount,
      DbHelper.CATEGORY_ID: categoryId,
      DbHelper.BUDGET_START_DATE: startDate.toIso8601String(),
      DbHelper.BUDGET_END_DATE: endDate.toIso8601String(),
      DbHelper.BUDGET_STATUS: status,
    };
  }
}

// --- Écran Principal ---
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  void _showAddOrEditBudgetSheet({BudgetWithDetails? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddOrEditBudgetForm(
        budget: budget,
        onSave: () {
          setState(() {}); // Rafraîchir l'UI
          Navigator.of(context).pop(); // Ferme le formulaire
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(budget != null ? 'Budget mis à jour avec succès.' : 'Budget créé avec succès.'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BudgetWithDetails budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Text('Supprimer le budget')]),
        content: Text('Êtes-vous sûr de vouloir supprimer le budget "${budget.name}" ?'),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          OutlinedButton(child: const Text('Annuler'), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            child: const Text('Supprimer'),
            onPressed: () async {
              if (budget.id != null) {
                await DbHelper.deleteBudget(budget.id!);
              }
              if (mounted) Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Budget "${budget.name}" supprimé.'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DbHelper.getBudgetsWithDetails(),
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
                  Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "Aucun budget défini",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Appuyez sur le bouton + pour en créer un.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          final budgets = snapshot.data!.map((map) => BudgetWithDetails.fromMap(map)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: budgets.length,
            itemBuilder: (context, index) => _buildBudgetCard(budgets[index]),
          );
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

  Widget _buildBudgetCard(BudgetWithDetails budget) {
    final progress = (budget.spentAmount / budget.amount).clamp(0.0, 1.0);
    final remaining = budget.amount - budget.spentAmount;
    final daysLeft = budget.endDate.difference(DateTime.now()).inDays;
    final progressColor = progress > 0.8 ? Colors.red : (progress > 1 ? Colors.orange : Colors.green);
    final bool isActive = budget.status == 1;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(_slideTransition(BudgetDetailScreen(budget: budget))),
        onLongPress: () => _showDeleteDialog(budget),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.5, // Grise le budget si inactif
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: budget.categoryColor?.withOpacity(0.2), child: Icon(budget.categoryIcon, color: budget.categoryColor)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(budget.categoryName ?? budget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    Text('${budget.spentAmount.toStringAsFixed(2)} / ${budget.amount.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                      onPressed: () => _showAddOrEditBudgetSheet(budget: budget),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(progressColor)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Restant: ${remaining.toStringAsFixed(2)} €', style: TextStyle(fontWeight: FontWeight.bold, color: remaining >= 0 ? Colors.black54 : Colors.red)),
                    Text(isActive ? (daysLeft > 0 ? '$daysLeft jours restants' : 'Terminé') : 'Inactif', style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Widget du Formulaire ---
class _AddOrEditBudgetForm extends StatefulWidget {
  final BudgetWithDetails? budget;
  final VoidCallback onSave;

  const _AddOrEditBudgetForm({this.budget, required this.onSave});

  @override
  State<_AddOrEditBudgetForm> createState() => _AddOrEditBudgetFormState();
}

class _AddOrEditBudgetFormState extends State<_AddOrEditBudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  int? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = DbHelper.getCategories('expense');
    if (widget.budget != null) {
      final b = widget.budget!;
      _nameController.text = b.name;
      _amountController.text = b.amount.toString();
      _selectedCategoryId = b.categoryId;
      _startDate = b.startDate;
      _endDate = b.endDate;
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;

    final budget = BudgetWithDetails(
      id: widget.budget?.id,
      name: _nameController.text,
      amount: double.parse(_amountController.text),
      categoryId: _selectedCategoryId,
      startDate: _startDate,
      endDate: _endDate,
      status: widget.budget?.status ?? 1,
    );

    if (widget.budget != null) {
      await DbHelper.updateBudget(budget.toMap());
    } else {
      await DbHelper.insertBudget(budget.toMap());
    }
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.budget != null ? 'Modifier le budget' : 'Nouveau budget', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(controller: _nameController, decoration: InputDecoration(labelText: 'Nom du budget', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Champ requis' : null),
              const SizedBox(height: 15),
              FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, snapshot) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  items: snapshot.hasData ? snapshot.data!.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList() : [],
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  decoration: InputDecoration(labelText: 'Catégorie de dépense', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v == null ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Montant', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Champ requis' : null),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildDatePickerField('Début', _startDate, (date) => setState(() => _startDate = date))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDatePickerField('Fin', _endDate, (date) => setState(() => _endDate = date))),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _saveBudget, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Enregistrer')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, Function(DateTime) onSelect) {
    return ListTile(
      onTap: () async {
        final pickedDate = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (pickedDate != null) onSelect(pickedDate);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.grey)),
      leading: const Icon(Icons.calendar_today_outlined), 
      title: Text(label),
      subtitle: Text(DateFormat('d MMM yyyy', 'fr_FR').format(date)),
    );
  }
}
