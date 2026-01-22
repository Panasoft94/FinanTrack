import 'package:budget/screens/accounts/accounts_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';

class VirementCompteScreen extends StatefulWidget {
  final Account? fromAccount;
  const VirementCompteScreen({Key? key, this.fromAccount}) : super(key: key);

  @override
  _VirementCompteScreenState createState() => _VirementCompteScreenState();
}

class _VirementCompteScreenState extends State<VirementCompteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  Account? _fromAccount;
  Account? _toAccount;
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _fromAccount = widget.fromAccount;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await DbHelper.getAccounts();
    setState(() {
      _accounts = accounts;
      // Si un compte source a été passé, on s'assure de pointer vers l'objet de la liste
      if (_fromAccount != null) {
        try {
          _fromAccount = _accounts.firstWhere((acc) => acc.id == _fromAccount!.id);
        } catch (e) {
          // Garder la valeur actuelle si non trouvée dans la liste
        }
      }
    });
  }

  void _performTransfer() async {
    if (_formKey.currentState!.validate()) {
      if (_fromAccount == null || _toAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner les deux comptes.')),
        );
        return;
      }

      if (_fromAccount!.id == _toAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les comptes de départ et d\'arrivée ne peuvent pas être identiques.')),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un montant valide.')),
        );
        return;
      }

      if (_fromAccount!.balance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le solde du compte de départ est insuffisant.')),
        );
        return;
      }

      // Perform the transfer (update balances)
      _fromAccount!.balance -= amount;
      _toAccount!.balance += amount;

      await DbHelper.updateAccount(_fromAccount!.toMap());
      await DbHelper.updateAccount(_toAccount!.toMap());

      // Create only the credit transaction as a 'Virement interne' type 
      final now = DateTime.now().toIso8601String();
      final transferTransaction = {
        DbHelper.MONTANT: amount,
        DbHelper.TRANSACTION_TYPE: 'Virement interne', 
        DbHelper.TRANSACTION_DATE: now,
        DbHelper.ACCOUNT_ID: _toAccount!.id,
        DbHelper.TRANSACTION_DESCRIPTION: 'Virement depuis ${_fromAccount!.name}',
      };

      await DbHelper.insertTransaction(transferTransaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Virement effectué avec succès!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter the list of accounts for the 'to' dropdown
    final toAccounts = _accounts.where((acc) {
      if (_fromAccount == null) return true;
      return acc.id != _fromAccount!.id;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virement entre Comptes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Effectuer un Virement',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Account>(
                value: _fromAccount,
                items: _accounts.map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(account.name),
                        Text(
                          '${account.balance.toStringAsFixed(2)} ${account.currencySymbol}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (account) {
                  setState(() {
                    _fromAccount = account;
                    if (_toAccount != null && _toAccount!.id == _fromAccount!.id) {
                      _toAccount = null;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Compte à débiter',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Account>(
                value: _toAccount,
                items: toAccounts.map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(account.name),
                        Text(
                          '${account.balance.toStringAsFixed(2)} ${account.currencySymbol}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (account) {
                  setState(() {
                    _toAccount = account;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Compte à créditer',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant du virement',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Effectuer le Virement'),
                onPressed: _performTransfer,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
