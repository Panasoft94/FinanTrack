import 'package:budget/models/transactions_model.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/virement_compte.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Approvisionner",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Ajouter des fonds au compte",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: widget.account.currencySymbol,
                suffixStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(_slideTransition(VirementCompteScreen(fromAccount: widget.account)));
                    },
                    icon: const Icon(Icons.sync_alt_rounded),
                    label: const Text('Virement'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.green.shade200),
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final amountText = amountController.text.replaceAll(',', '.');
                      final amount = double.tryParse(amountText);
                      if (amount != null && amount > 0) {
                        widget.account.balance += amount;
                        await DbHelper.updateAccount(widget.account.toMap());

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
                            backgroundColor: Colors.green[800],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Confirmer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                Text("HISTORIQUE RÉCENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey[600])),
                const SizedBox(width: 12),
                const Expanded(child: Divider(thickness: 1)),
              ],
            ),
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
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Aucune transaction récente",
                          style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Vos dépenses et revenus apparaîtront ici",
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Approvisionner', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            "Solde du compte",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500], letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatAmount(widget.account.balance)} ${widget.account.currencySymbol}',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: -1),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(Icons.info_outline_rounded, "Type", widget.account.name),
              Container(height: 30, width: 1, color: Colors.grey[200]),
              _buildInfoItem(Icons.category_rounded, "Catégorie", widget.account.type),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTransactionList(List<TransactionWithDetails> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isExpense = transaction.type == 'expense';
        final color = isExpense ? Colors.red.shade700 : Colors.green.shade700;
        final icon = isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(
              transaction.description ?? transaction.categoryName ?? 'Transaction',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy', 'fr_FR').format(transaction.date),
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            trailing: Text(
              '${isExpense ? '−' : '+'}${_formatAmount(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
