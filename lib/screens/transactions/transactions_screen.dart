import 'package:another_flushbar/flushbar.dart';
import 'package:budget/models/transactions_model.dart';
import 'package:budget/screens/accounts/accounts_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/expense_category/expense_category_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


// --- Écran Principal ---
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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
              content: Text(transaction != null ? 'Transaction modifiée avec succès.' : 'Transaction effectuée avec succès.'),
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
    final searchAction = IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {
        setState(() {
          _isSearching = true;
        });
      },
    );

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Transactions', icon: Icon(Icons.list_alt, color: Colors.white)),
            Tab(text: 'Tendances', icon: Icon(Icons.trending_up, color: Colors.white)),
          ],
        ),
      );
    } else {
      return AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.swap_horiz), SizedBox(width: 8), Text('Transactions')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [searchAction],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Transactions', icon: Icon(Icons.list_alt, color: Colors.white)),
            Tab(text: 'Tendances', icon: Icon(Icons.trending_up, color: Colors.white)),
          ],
        ),
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

          final allTransactions = snapshot.hasData 
              ? snapshot.data!.map((map) => TransactionWithDetails.fromMap(map)).toList() 
              : <TransactionWithDetails>[];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsList(allTransactions),
              _buildTrendsView(allTransactions),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditTransactionSheet(), 
        backgroundColor: Colors.green, 
        foregroundColor: Colors.white, 
        child: const Icon(Icons.add), 
        tooltip: 'Ajouter une transaction'
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionWithDetails> allTransactions) {
    if (allTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: "Aucune transaction",
        subtitle: "Appuyez sur le bouton + pour commencer.",
      );
    }

    final filteredTransactions = allTransactions.where((t) {
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      return (t.description?.toLowerCase().contains(query) ?? false) ||
          (t.categoryName?.toLowerCase().contains(query) ?? false) ||
          (t.accountName?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: "Aucun résultat",
        subtitle: "Aucune transaction ne correspond à '$_searchQuery'.",
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dailyTransactions = groupedTransactions[date]!;

        final double dailyIncome = dailyTransactions.where((t) => t.type == 'income' && t.categoryName != 'Virement Interne').fold(0, (sum, t) => sum + t.amount);
        final double dailyExpense = dailyTransactions.where((t) => t.type == 'expense' && t.categoryName != 'Virement Interne').fold(0, (sum, t) => sum + t.amount);
        final double dailyNet = dailyIncome - dailyExpense;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8, left: 8),
              child: Text(
                DateFormat('EEEE, d MMMM yyyy', 'fr_FR').format(date), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)
              ),
            ),
            _buildDailySummaryCard(dailyIncome, dailyExpense, dailyNet),
            ...dailyTransactions.map((t) => _buildTransactionCard(t)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsView(List<TransactionWithDetails> allTransactions) {
    if (allTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trending_up,
        title: "Pas de données",
        subtitle: "Ajoutez des transactions pour voir l'évolution.",
      );
    }

    // Calculer les données pour les 7 derniers jours
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return DateTime(date.year, date.month, date.day);
    });

    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> incomeSpots = [];
    double maxAmount = 0;

    for (int i = 0; i < last7Days.length; i++) {
      final day = last7Days[i];
      final dayTransactions = allTransactions.where((t) {
        return t.date.year == day.year && t.date.month == day.month && t.date.day == day.day;
      }).toList();

      final dailyExpense = dayTransactions.where((t) => t.type == 'expense' && t.categoryName != 'Virement Interne').fold(0.0, (sum, t) => sum + t.amount);
      final dailyIncome = dayTransactions.where((t) => t.type == 'income' && t.categoryName != 'Virement Interne').fold(0.0, (sum, t) => sum + t.amount);

      expenseSpots.add(FlSpot(i.toDouble(), dailyExpense));
      incomeSpots.add(FlSpot(i.toDouble(), dailyIncome));

      if (dailyExpense > maxAmount) maxAmount = dailyExpense;
      if (dailyIncome > maxAmount) maxAmount = dailyIncome;
    }

    // Ajuster maxAmount pour le graphique
    maxAmount = maxAmount == 0 ? 1000 : maxAmount * 1.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tendance Hebdomadaire",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Evolution de vos revenus et dépenses sur les 7 derniers jours.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          Container(
            height: 300,
            padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= last7Days.length) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E', 'fr_FR').format(last7Days[index]),
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        String text = '';
                        if (value >= 1000000) {
                          text = '${(value / 1000000).toStringAsFixed(1)}M';
                        } else if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(0)}k';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxAmount,
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final prefix = spot.barIndex == 0 ? 'Revenu: ' : 'Dépense: ';
                        return LineTooltipItem(
                          '$prefix${_formatAmount(spot.y)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(),
          const SizedBox(height: 30),
          _buildTrendInsight(allTransactions),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Revenus", Colors.green),
        const SizedBox(width: 24),
        _legendItem("Dépenses", Colors.red),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
      ],
    );
  }

  Widget _buildTrendInsight(List<TransactionWithDetails> allTransactions) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final lastWeekTransactions = allTransactions.where((t) => t.date.isAfter(sevenDaysAgo)).toList();
    final double totalIncome = lastWeekTransactions.where((t) => t.type == 'income' && t.categoryName != 'Virement Interne').fold(0.0, (sum, t) => sum + t.amount);
    final double totalExpense = lastWeekTransactions.where((t) => t.type == 'expense' && t.categoryName != 'Virement Interne').fold(0.0, (sum, t) => sum + t.amount);
    final double balance = totalIncome - totalExpense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Analyse de la semaine", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            balance >= 0 
              ? "Bonne gestion ! Votre solde est positif cette semaine de ${_formatAmount(balance)} FCFA."
              : "Attention, vos dépenses dépassent vos revenus de ${_formatAmount(balance.abs())} FCFA cette semaine.",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _insightMiniStat("Revenus", totalIncome, Icons.trending_up),
              _insightMiniStat("Dépenses", totalExpense, Icons.trending_down),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightMiniStat(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(_formatAmount(amount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildDailySummaryCard(double income, double expense, double net) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Revenus', income, Colors.green),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildSummaryItem('Dépenses', expense, Colors.red),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildSummaryItem('Net', net, net >= 0 ? Colors.blue : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          _formatAmount(amount), 
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionWithDetails transaction) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.red.shade700 : Colors.green.shade700;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade50),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddOrEditTransactionSheet(transaction: transaction),
          onLongPress: () => _showDeleteDialog(transaction),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline, 
                    color: color, 
                    size: 24
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description?.isNotEmpty == true ? transaction.description! : (transaction.categoryName ?? 'Transaction'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            transaction.accountName ?? 'Compte inconnu', 
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'} ${_formatAmount(transaction.amount)} FCFA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
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

    final description = _descriptionController.text;
    if (description.isNotEmpty) {
      await DbHelper.insertIntoDictionnaire(description);
    }

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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                widget.transaction != null ? 'Modifier la transaction' : 'Nouvelle transaction', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = 'expense';
                          _categoriesFuture = DbHelper.getCategories(_type);
                          _selectedCategoryId = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == 'expense' ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Dépense', 
                              style: TextStyle(
                                color: _type == 'expense' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = 'income';
                          _categoriesFuture = DbHelper.getCategories(_type);
                          _selectedCategoryId = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == 'income' ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Revenu', 
                              style: TextStyle(
                                color: _type == 'income' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: _amountController, 
                keyboardType: TextInputType.number, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Montant', 
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'FCFA',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green, width: 2)),
                )
              ),
              const SizedBox(height: 15),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return await DbHelper.getDictionnaireSuggestions(textEditingValue.text);
                },
                onSelected: (String selection) {
                  _descriptionController.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  // Synchroniser _descriptionController avec le contrôleur d'Autocomplete
                  if (fieldTextEditingController.text != _descriptionController.text) {
                    fieldTextEditingController.text = _descriptionController.text;
                  }

                  fieldTextEditingController.addListener(() {
                    _descriptionController.text = fieldTextEditingController.text;
                  });

                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      prefixIcon: const Icon(Icons.description_outlined),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green, width: 2)),
                    ),
                    onFieldSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                  );
                },
                optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 6.0,
                      color: Colors.transparent,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 250),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * -10),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width - 40,
                          margin: const EdgeInsets.only(top: 5),
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.history, size: 20, color: Colors.green),
                                  title: Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  onTap: () => onSelected(option),
                                  hoverColor: Colors.green.withOpacity(0.05),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              FutureBuilder<List<Account>>(
                future: _accountsFuture,
                builder: (context, snapshot) => DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'Compte', 
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
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
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    validator: (val) => val == null ? 'Veuillez sélectionner une catégorie.' : null,
                  );
                },
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (pickedDate != null) setState(() => _selectedDate = pickedDate);
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveTransaction, 
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55), 
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ), 
                child: Text(widget.transaction != null ? 'Modifier' : 'Enregistrer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
      ),
    );
  }
}
