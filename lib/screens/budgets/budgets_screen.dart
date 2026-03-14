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

  // Helper list to solve tree-shaking issue
  static final List<IconData> _availableIcons = [
    Icons.shopping_cart, Icons.fastfood, Icons.directions_car, Icons.movie,
    Icons.house, Icons.work, Icons.savings, Icons.receipt_long,
    Icons.medical_services, Icons.school, Icons.local_gas_station, Icons.phone_android,
    Icons.train, Icons.lightbulb_outline, Icons.pets, Icons.book,
  ];

  static IconData _iconFromString(String iconString) {
    try {
      int codePoint = int.parse(iconString);
      return _availableIcons.firstWhere(
        (icon) => icon.codePoint == codePoint,
        orElse: () => Icons.error_outline,
      );
    } catch (e) {
      return Icons.error_outline;
    }
  }

  factory BudgetWithDetails.fromMap(Map<String, dynamic> map) {
    final iconString = map[DbHelper.CATEGORY_ICON]?.toString();
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
      categoryIcon: iconString != null ? _iconFromString(iconString) : null,
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

  String _formatAmount(double amount) {
    // Utilisation de NumberFormat pour ajouter les séparateurs de milliers
    // Le format 'fr_FR' utilise l'espace comme séparateur
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.pie_chart_outline), SizedBox(width: 8), Text('Budgets')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
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
          budgets.sort((a, b) => a.amount.compareTo(b.amount));
          
          final activeBudgets = budgets.where((b) => b.status == 1).toList();
          final double totalBudget = activeBudgets.fold(0.0, (sum, b) => sum + b.amount);
          final double totalSpent = activeBudgets.fold(0.0, (sum, b) => sum + b.spentAmount);

          return ListView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
            children: [
              _buildOverallSummaryCard(totalBudget, totalSpent),
               const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("Détails par Budget", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              ...budgets.map((budget) => _buildBudgetCard(budget)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditBudgetSheet(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un budget',
      ),
    );
  }

  Widget _buildOverallSummaryCard(double totalAmount, double totalSpent) {
    if (totalAmount == 0) {
      return const SizedBox.shrink();
    }

    final double progress = (totalSpent / totalAmount).clamp(0.0, 1.0);
    final double remaining = totalAmount - totalSpent;
    final Color progressColor = progress >= 1.0 ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.greenAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Text(
                  "État Général des Budgets",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dépensé total",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatAmount(totalSpent)} FCFA",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${(progress * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Restant global :',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${_formatAmount(remaining)} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: remaining >= 0 ? Colors.white : Colors.redAccent.shade100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetWithDetails budget) {
    final progress = (budget.spentAmount / budget.amount).clamp(0.0, 1.0);
    final remaining = budget.amount - budget.spentAmount;
    final daysLeft = budget.endDate.difference(DateTime.now()).inDays;
    final progressColor = remaining < 0 ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.green);
    final bool isActive = budget.status == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(_slideTransition(BudgetDetailScreen(budget: budget))),
          onLongPress: () => _showDeleteDialog(budget),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: budget.categoryColor?.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(budget.categoryIcon, color: budget.categoryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              budget.categoryName ?? 'Pas de catégorie',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 22),
                        onPressed: () => _showAddOrEditBudgetSheet(budget: budget),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Utilisé", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            _formatAmount(budget.spentAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Budget total", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            "${_formatAmount(budget.amount)} FCFA",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              if (progress > 0)
                                BoxShadow(
                                  color: progressColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            remaining >= 0 ? Icons.check_circle_outline : Icons.error_outline,
                            size: 14,
                            color: remaining >= 0 ? Colors.blueGrey : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Restant: ${_formatAmount(remaining)} FCFA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: remaining >= 0 ? Colors.black54 : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (isActive)
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              daysLeft > 0 ? '$daysLeft j.' : 'Terminé',
                              style: const TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
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
    outlineInputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: 1.5),
    );

    return Padding(
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                widget.budget != null ? 'Modifier le budget' : 'Nouveau budget',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du budget',
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: Colors.green),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: outlineInputBorder(Colors.grey.shade300),
                  enabledBorder: outlineInputBorder(Colors.grey.shade300),
                  focusedBorder: outlineInputBorder(Colors.green),
                ),
                validator: (v) => v!.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, snapshot) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  items: snapshot.hasData
                      ? snapshot.data!.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList()
                      : [],
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  decoration: InputDecoration(
                    labelText: 'Catégorie de dépense',
                    prefixIcon: const Icon(Icons.category_outlined, color: Colors.green),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: outlineInputBorder(Colors.grey.shade300),
                    enabledBorder: outlineInputBorder(Colors.grey.shade300),
                    focusedBorder: outlineInputBorder(Colors.green),
                  ),
                  validator: (v) => v == null ? 'Veuillez choisir une catégorie' : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant du budget',
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.green),
                  suffixText: 'FCFA',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: outlineInputBorder(Colors.grey.shade300),
                  enabledBorder: outlineInputBorder(Colors.grey.shade300),
                  focusedBorder: outlineInputBorder(Colors.green),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Veuillez entrer un montant';
                  if (double.tryParse(v) == null) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text("Période du budget", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDatePickerField('Début', _startDate, (date) => setState(() => _startDate = date))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDatePickerField('Fin', _endDate, (date) => setState(() => _endDate = date))),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(widget.budget != null ? 'Mettre à jour' : 'Créer le budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Colors.green, onPrimary: Colors.white, onSurface: Colors.black),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) onSelect(pickedDate);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('d MMM yyyy', 'fr_FR').format(date),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
