import 'package:budget/models/transactions_model.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/virement_compte.dart';
import 'package:flutter/material.dart';
import './accounts_screen.dart'; // Importer pour la classe Account

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {

  void _showAddFundsDialog() {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_card_outlined, color: Colors.green),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Approvisionner",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Montant à ajouter',
                hintText: '0.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[50],
                suffixText: widget.account.currencySymbol,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(_slideTransition(VirementCompteScreen(fromAccount: widget.account)));
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Virement Compte', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount != null && amount > 0) {
                        // 1. Mettre à jour le solde du compte
                        widget.account.balance += amount;
                        await DbHelper.updateAccount(widget.account.toMap());

                        // 2. Créer la transaction correspondante
                        final transactionData = {
                          DbHelper.MONTANT: amount,
                          DbHelper.TRANSACTION_TYPE: 'income',
                          DbHelper.TRANSACTION_DATE: DateTime.now().toIso8601String(),
                          DbHelper.ACCOUNT_ID: widget.account.id,
                          DbHelper.TRANSACTION_DESCRIPTION: 'Approvisionnement du compte',
                        };
                        await DbHelper.insertTransaction(transactionData);

                        if (!mounted) return;

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_formatAmount(amount)} ${widget.account.currencySymbol} ajoutés avec succès.'),
                            backgroundColor: Colors.green[700],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        // 3. Rafraîchir l'écran
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Ajouter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncate()) {
      return amount.truncate().toString();
    } else {
      return amount.toStringAsFixed(2);
    }
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
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.analytics_outlined), 
          const SizedBox(width: 8), 
          Text(widget.account.name)
        ]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [Expanded(child: Divider()), Text("  Transactions récentes  ", style: TextStyle(color: Colors.grey)), Expanded(child: Divider())]),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DbHelper.getTransactionsForAccount(widget.account.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          "Aucune transaction pour ce compte.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                final transactions = snapshot.data!.map((map) => TransactionWithDetails.fromMap(map)).toList();
                return _buildTransactionList(transactions);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFundsDialog,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Approvisionner'),
        tooltip: 'Approvisionner le compte',
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.green.withOpacity(0.1),
      child: Column(
        children: [
          Text("Solde actuel", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(
            '${_formatAmount(widget.account.balance)} ${widget.account.currencySymbol}',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text("Type: ${widget.account.type}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionWithDetails> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (transaction.type == 'expense' ? Colors.red : Colors.green).withOpacity(0.1),
                  child: Icon(
                    transaction.type == 'expense' ? Icons.arrow_downward : Icons.arrow_upward,
                    color: transaction.type == 'expense' ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description ?? transaction.categoryName ?? 'Transaction',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${transaction.date.day}/${transaction.date.month}/${transaction.date.year}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${transaction.type == 'expense' ? '−' : '+'}${_formatAmount(transaction.amount)} ${widget.account.currencySymbol}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: transaction.type == 'expense' ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
