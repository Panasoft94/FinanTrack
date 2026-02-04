import 'package:another_flushbar/flushbar.dart';
import 'package:budget/models/transactions_model.dart';
import 'package:budget/screens/accounts/accounts_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/expense_category/expense_category_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


// --- Écran Principal ---
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    if (amount == amount.truncate()) {
      return formatter.format(amount.truncate());
    } else {
      return NumberFormat('#,##0.00', 'fr_FR').format(amount);
    }
  }

  void _showAddOrEditTransactionSheet({TransactionWithDetails? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddOrEditTransactionForm(
        transaction: transaction,
        onSave: () {
          setState(() {}); // Rafraîchit l'écran principal
          Navigator.of(context).pop(); // Ferme le BottomSheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(transaction != null ? 'Transaction modifiée avec succès.' : 'Transaction ajoutée avec succès.'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(TransactionWithDetails transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Expanded(child: Text('Supprimer la transaction'))]),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette transaction ? L\'action est irréversible.'),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          OutlinedButton(child: const Text('Retour'), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            child: const Text('Supprimer'),
            onPressed: () async {
              // Mise à jour du solde du compte avant suppression
              if (transaction.accountId != null) {
                final accounts = await DbHelper.getAccounts();
                final account = accounts.firstWhere((acc) => acc.id == transaction.accountId);
                if (transaction.type == 'expense') {
                  account.balance += transaction.amount;
                } else {
                  account.balance -= transaction.amount;
                }
                await DbHelper.updateAccount(account.toMap());
              }

              await DbHelper.deleteTransaction(transaction.id!);
              if (mounted) Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Transaction supprimée.'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: const Icon(Icons.search, color: Colors.white),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _isSearching = false;
              });
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.swap_horiz), SizedBox(width: 8), Text('Transactions')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DbHelper.getTransactionsWithDetails(),
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
                  Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "Aucune transaction",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Appuyez sur le bouton + pour commencer.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final allTransactions = snapshot.data!.map((map) => TransactionWithDetails.fromMap(map)).toList();

          final filteredTransactions = allTransactions.where((t) {
            final query = _searchQuery.toLowerCase();
            if (query.isEmpty) return true;
            return (t.description?.toLowerCase().contains(query) ?? false) ||
                (t.categoryName?.toLowerCase().contains(query) ?? false) ||
                (t.accountName?.toLowerCase().contains(query) ?? false);
          }).toList();

          if (filteredTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_searchQuery.isEmpty ? Icons.receipt_long_outlined : Icons.search_off, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isEmpty ? "Aucune transaction" : "Aucun résultat",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty ? "Appuyez sur le bouton + pour commencer." : "Aucune transaction ne correspond à '$_searchQuery'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Grouper les transactions par jour
          final Map<DateTime, List<TransactionWithDetails>> groupedTransactions = {};
          for (var t in filteredTransactions) {
            final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
            if (groupedTransactions[dateKey] == null) {
              groupedTransactions[dateKey] = [];
            }
            groupedTransactions[dateKey]!.add(t);
          }

          final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dailyTransactions = groupedTransactions[date]!;

              // Calculer les totaux de la journée
              final double dailyIncome = dailyTransactions.where((t) => t.type == 'income').fold(0, (sum, t) => sum + t.amount);
              final double dailyExpense = dailyTransactions.where((t) => t.type == 'expense').fold(0, (sum, t) => sum + t.amount);
              final double dailyNet = dailyIncome - dailyExpense;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8, left: 8),
                    child: Text(DateFormat('EEEE, d MMMM yyyy', 'fr_FR').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
                  ),
                  _buildDailySummaryCard(dailyIncome, dailyExpense, dailyNet),
                  ...dailyTransactions.map((t) => _buildTransactionCard(t)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddOrEditTransactionSheet(), backgroundColor: Colors.green, foregroundColor: Colors.white, child: const Icon(Icons.add), tooltip: 'Ajouter une transaction'),
    );
  }

  Widget _buildDailySummaryCard(double income, double expense, double net) {
    return Card(
      elevation: 1,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn('Revenus', income, Colors.green[700]!),
            _buildSummaryColumn('Dépenses', expense, Colors.red[700]!),
            _buildSummaryColumn('Solde net', net, net >= 0 ? Colors.blue[800]! : Colors.red[700]!),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text('${_formatAmount(amount)} FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionWithDetails transaction) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.red[700]! : Colors.green[700]!;
    final icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showAddOrEditTransactionSheet(transaction: transaction),
        onLongPress: () => _showDeleteDialog(transaction),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(transaction.description ?? transaction.categoryName ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(transaction.accountName ?? 'Compte non spécifié', style: TextStyle(color: Colors.grey[600])),
        trailing: Text('${isExpense ? '-' : '+'} ${_formatAmount(transaction.amount)} FCFA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ),
    );
  }
}

// --- Widget du Formulaire ---
class _AddOrEditTransactionForm extends StatefulWidget {
  final TransactionWithDetails? transaction;
  final VoidCallback onSave;

  const _AddOrEditTransactionForm({this.transaction, required this.onSave});

  @override
  State<_AddOrEditTransactionForm> createState() => _AddOrEditTransactionFormState();
}

class _AddOrEditTransactionFormState extends State<_AddOrEditTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'expense';
  int? _selectedAccountId;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  late Future<List<Account>> _accountsFuture;
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = DbHelper.getAccounts();
    _categoriesFuture = DbHelper.getCategories(_type);

    if (widget.transaction != null) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toString();
      _descriptionController.text = t.description ?? '';
      _type = t.type;
      _selectedAccountId = t.accountId;
      _selectedCategoryId = t.categoryId;
      _selectedDate = t.date;
      _categoriesFuture = DbHelper.getCategories(t.type); // Charger les bonnes catégories
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    if (amount == amount.truncate()) {
      return formatter.format(amount.truncate());
    } else {
      return NumberFormat('#,##0.00', 'fr_FR').format(amount);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _selectedAccountId == null || _selectedCategoryId == null) return;

    final isEditing = widget.transaction != null;
    final amount = double.parse(_amountController.text);
    final accounts = await _accountsFuture;
    final account = accounts.firstWhere((acc) => acc.id == _selectedAccountId);

    if (_type == 'expense') {
      double balanceToCheck = account.balance;
      if (isEditing && widget.transaction!.type == 'expense' && widget.transaction!.accountId == _selectedAccountId) {
        balanceToCheck += widget.transaction!.amount;
      }

      if (balanceToCheck < amount) {
        if (!mounted) return;
        Flushbar(
          title: 'Solde Insuffisant',
          message: 'Le solde du compte "${account.name}" (${_formatAmount(account.balance)} FCFA) est insuffisant pour cette opération.',
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red[700]!,
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        ).show(context);
        return;
      }
    }

    // --- LOGIQUE DE MISE A JOUR DU SOLDE ---
    if (isEditing) {
      final oldAmount = widget.transaction!.amount;
      if (widget.transaction!.type == 'expense') {
        account.balance += oldAmount;
      } else {
        account.balance -= oldAmount;
      }
    }

    if (_type == 'expense') {
      account.balance -= amount;
    } else {
      account.balance += amount;
    }
    await DbHelper.updateAccount(account.toMap());
    // --- FIN DE LA LOGIQUE ---

    final data = {
      DbHelper.TRANSACTION_ID: widget.transaction?.id,
      DbHelper.MONTANT: amount,
      DbHelper.TRANSACTION_TYPE: _type,
      DbHelper.ACCOUNT_ID: _selectedAccountId,
      DbHelper.CATEGORY_ID: _selectedCategoryId,
      DbHelper.TRANSACTION_DATE: _selectedDate.toIso8601String(),
      DbHelper.TRANSACTION_DESCRIPTION: _descriptionController.text,
    };

    if (isEditing) {
      await DbHelper.updateTransaction(data);
    } else {
      await DbHelper.insertTransaction(data);
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
              Text(widget.transaction != null ? 'Modifier la transaction' : 'Nouvelle transaction', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'expense', label: Text('Dépense')), ButtonSegment(value: 'income', label: Text('Revenu'))],
                selected: {_type},
                onSelectionChanged: (newSelection) => setState(() {
                  _type = newSelection.first;
                  _categoriesFuture = DbHelper.getCategories(_type);
                  _selectedCategoryId = null; // Réinitialiser la catégorie
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Montant', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description (optionnel)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              FutureBuilder<List<Account>>(
                future: _accountsFuture,
                builder: (context, snapshot) => DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  items: snapshot.hasData
                      ? snapshot.data!.map((acc) {
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(acc.name),
                          Text(
                            '${_formatAmount(acc.balance)} ${acc.currencySymbol}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                      : [],
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                  decoration: InputDecoration(labelText: 'Compte', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (val) => val == null ? 'Veuillez sélectionner un compte.' : null,
                ),
              ),
              const SizedBox(height: 15),
              FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Sort the categories alphabetically
                  final sortedCategories = snapshot.data!;
                  sortedCategories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    items: sortedCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) => val == null ? 'Veuillez sélectionner une catégorie.' : null,
                  );
                },
              ),
              const SizedBox(height: 15),
              ListTile(
                onTap: () async {
                  final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (pickedDate != null) setState(() => _selectedDate = pickedDate);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.grey)),
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDate)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _saveTransaction, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Enregistrer')),
            ],
          ),
        ),
      ),
    );
  }
}
