import 'package:budget/screens/accounts/account_detail_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';

// Modèle de données pour un compte, avec conversion Map
class Account {
  int? id;
  String name;
  String type;
  double balance;
  String currencySymbol;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currencySymbol = 'FCFA',
  });

  // Convertit un Map en objet Account
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map[DbHelper.ACCOUNT_ID],
      name: map[DbHelper.ACCOUNT_NAME],
      type: map[DbHelper.ACCOUNT_TYPE],
      balance: (map[DbHelper.ACCOUNT_BALANCE] as num).toDouble(),
      currencySymbol: map[DbHelper.ACCOUNT_ICON],
    );
  }

  // Convertit un objet Account en Map
  Map<String, dynamic> toMap() {
    return {
      DbHelper.ACCOUNT_ID: id,
      DbHelper.ACCOUNT_NAME: name,
      DbHelper.ACCOUNT_TYPE: type,
      DbHelper.ACCOUNT_BALANCE: balance,
      DbHelper.ACCOUNT_ICON: currencySymbol,
      DbHelper.ACCOUNT_UPDATED_AT: DateTime.now().toIso8601String(),
    };
  }
}

// --- Écran Principal ---
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {

  // Sauvegarde un compte (création ou mise à jour)
  Future<void> _onSaveAccount(Account? account, String name, double balance, String type, String currency) async {
    final newOrUpdatedAccount = Account(
      id: account?.id,
      name: name,
      type: type,
      balance: balance,
      currencySymbol: currency,
    );

    final isEditing = account != null;

    if (isEditing) {
      await DbHelper.updateAccount(newOrUpdatedAccount.toMap());
    } else {
      await DbHelper.insertAccount(newOrUpdatedAccount.toMap());
    }
    
    if (!mounted) return;

    Navigator.of(context).pop(); // Ferme le BottomSheet

    final message = isEditing ? 'Compte mis à jour avec succès' : 'Compte ajouté avec succès';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {}); // Rafraîchit l'écran
  }

  // Ouvre le panneau pour ajouter ou modifier un compte
  void _showAddOrEditAccountSheet({Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddOrEditAccountForm(
        account: account,
        onSave: _onSaveAccount,
      ),
    );
  }

  // Affiche la confirmation de suppression
  void _showDeleteDialog(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Expanded(child: Text('Supprimer le compte'))]),
        content: Text('Êtes-vous sûr de vouloir supprimer le compte "${account.name}" ?'),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          OutlinedButton.icon(icon: const Icon(Icons.cancel_outlined), label: const Text('Annuler'), onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[800], side: BorderSide(color: Colors.grey[400]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
          ElevatedButton.icon(icon: const Icon(Icons.delete_forever), label: const Text('Supprimer'), onPressed: () async {
            if (account.id != null) {
              await DbHelper.deleteAccount(account.id!);
            }
            if (!mounted) return;
            Navigator.of(context).pop(); // Ferme la boîte de dialogue
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Compte "${account.name}" supprimé.'),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() {}); // Rafraîchit l'écran
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
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
    if (amount == amount.truncate()) {
      return amount.truncate().toString();
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_balance_wallet), SizedBox(width: 8), Text('Gérer les comptes')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Account>>(
        future: DbHelper.getAccounts(), // Appel asynchrone à la base de données
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text('Aucun compte trouvé', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                Text('Cliquez sur le bouton + pour en ajouter un.', style: TextStyle(color: Colors.grey[500]))
              ]),
            );
          } else {
            final accounts = snapshot.data!;
            final totalBalance = accounts.fold(0.0, (sum, account) => sum + account.balance);

            accounts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            return Column(
              children: [
                _buildTotalBalanceCard(totalBalance),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(children: [Expanded(child: Divider()), Text("  Tous les comptes  ", style: TextStyle(color: Colors.grey)), Expanded(child: Divider())]),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) => _buildAccountCard(accounts[index]),
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditAccountSheet(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un compte',
      ),
    );
  }

  Widget _buildTotalBalanceCard(double totalBalance) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade700,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Solde Total',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${_formatAmount(totalBalance)} FCFA',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final Map<String, IconData> typeIcons = {
      "Banque": Icons.account_balance,
      "Espèces": Icons.money,
      "Épargne": Icons.savings,
    };
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(_slideTransition(AccountDetailScreen(account: account)));
        },
        onLongPress: () => _showDeleteDialog(account),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row for Icon, Name and Edit button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(typeIcons[account.type] ?? Icons.credit_card, size: 32, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      account.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 22),
                    onPressed: () => _showAddOrEditAccountSheet(account: account),
                    color: Colors.grey[500],
                    splashRadius: 20,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Spacing
              // Bottom row for Type and Balance
              Padding(
                padding: const EdgeInsets.only(left: 44.0), // Indent to align with name
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Solde disponible ', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                    Text(
                      '${_formatAmount(account.balance)} ${account.currencySymbol}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widget du Formulaire (isolé pour gérer son propre état) ---
class _AddOrEditAccountForm extends StatefulWidget {
  final Account? account;
  final Future<void> Function(Account? account, String name, double balance, String type, String currency) onSave;

  const _AddOrEditAccountForm({this.account, required this.onSave});

  @override
  _AddOrEditAccountFormState createState() => _AddOrEditAccountFormState();
}

class _AddOrEditAccountFormState extends State<_AddOrEditAccountForm> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _currencyController = TextEditingController();
  late String _selectedType;

  final List<String> _accountTypes = ["Banque", "Espèces", "Épargne"];

  @override
  void initState() {
    super.initState();
    final isEditing = widget.account != null;
    if (isEditing) {
      _nameController.text = widget.account!.name;
      final balance = widget.account!.balance;
      _balanceController.text = (balance == balance.truncate()) ? balance.truncate().toString() : balance.toStringAsFixed(2);
      _currencyController.text = widget.account!.currencySymbol;
      _selectedType = widget.account!.type;
    } else {
      _selectedType = _accountTypes.first;
      _currencyController.text = 'FCFA';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.account != null ? 'Modifier le compte' : 'Nouveau compte', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nameController, decoration: _buildInputDecoration('Nom du compte', Icons.drive_file_rename_outline)),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedType,
            items: _accountTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            decoration: _buildInputDecoration('Type', Icons.account_tree_outlined),
            onChanged: (newValue) => setState(() => _selectedType = newValue!),
          ),
          const SizedBox(height: 15),
          TextField(controller: _balanceController, keyboardType: TextInputType.number, decoration: _buildInputDecoration('Solde initial', Icons.attach_money)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            onPressed: () {
              final name = _nameController.text;
              final balance = double.tryParse(_balanceController.text) ?? 0.0;
              if (name.isNotEmpty) {
                widget.onSave(widget.account, name, balance, _selectedType, _currencyController.text);
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
  }
}
