import 'package:budget/screens/accounts/accounts_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Nouvelle fonction pour formater le montant avec séparateur de milliers et sans décimales si elles sont nulles
  String _formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    if (amount == amount.truncate()) {
      return formatter.format(amount.truncate());
    } else {
      // Pour les cas avec décimales, on utilise deux décimales par défaut
      return NumberFormat.currency(locale: 'fr_FR', symbol: '').format(amount);
    }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Virement Interne',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              // Action pour historique si nécessaire
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swap_horizontal_circle, color: Colors.green, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Transférer des fonds',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildAccountDropdown(
                      label: 'Compte à débiter',
                      value: _fromAccount,
                      icon: Icons.upload_rounded,
                      iconColor: Colors.red,
                      items: _accounts,
                      onChanged: (account) {
                        setState(() {
                          _fromAccount = account;
                          if (_toAccount != null && _toAccount!.id == _fromAccount!.id) {
                            _toAccount = null;
                          }
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Divider(color: Colors.grey[200], thickness: 1),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_downward_rounded, color: Colors.green.shade700, size: 20),
                          ),
                        ],
                      ),
                    ),
                    _buildAccountDropdown(
                      label: 'Compte à créditer',
                      value: _toAccount,
                      icon: Icons.download_rounded,
                      iconColor: Colors.green,
                      items: toAccounts,
                      onChanged: (account) {
                        setState(() {
                          _toAccount = account;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                ' Montant du virement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: 'FCFA',
                  suffixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
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
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _performTransfer,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 12),
                      Text(
                        'Confirmer le Virement',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required Account? value,
    required IconData icon,
    required Color iconColor,
    required List<Account> items,
    required Function(Account?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Account>(
          value: value,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.grey),
          elevation: 16,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            border: InputBorder.none,
          ),
          hint: Text('Sélectionner un compte', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          items: items.map((account) {
            return DropdownMenuItem<Account>(
              value: account,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Solde: ${_formatAmount(account.balance)} ${account.currencySymbol}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
