import 'package:budget/screens/accounts/account_detail_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    setState(() {}); // Rafraîchit l'écran
  }

  // Ouvre le panneau pour ajouter ou modifier un compte
  void _showAddOrEditAccountSheet({Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: _AddOrEditAccountForm(
          account: account,
          onSave: _onSaveAccount,
        ),
      ),
    );
  }

  // Affiche la confirmation de suppression
  void _showDeleteDialog(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
          ),
          const SizedBox(width: 15),
          const Expanded(child: Text('Supprimer le compte', style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        content: Text('Êtes-vous sûr de vouloir supprimer le compte "${account.name}" ?\n\nCette action est irréversible.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (account.id != null) {
                await DbHelper.deleteAccount(account.id!);
              }
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Compte "${account.name}" supprimé.'),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gérer les comptes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddOrEditAccountSheet(),
            tooltip: 'Ajouter un compte',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Account>>(
        future: DbHelper.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                  child: Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                Text('Aucun compte trouvé', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 8),
                Text('Cliquez sur le bouton + pour en ajouter un.', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _showAddOrEditAccountSheet(),
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter un compte"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ]),
            );
          } else {
            final accounts = snapshot.data!;
            final totalBalance = accounts.fold(0.0, (sum, account) => sum + account.balance);
            accounts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildTotalBalanceCard(totalBalance)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text("VOS COMPTES", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[600])),
                        const SizedBox(width: 10),
                        const Expanded(child: Divider(thickness: 1)),
                        const SizedBox(width: 10),
                        Text("${accounts.length}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildAccountCard(accounts[index]),
                    ),
                    childCount: accounts.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditAccountSheet(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text("Nouveau compte", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTotalBalanceCard(double totalBalance) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.account_balance_wallet, size: 150, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solde Total Global',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatAmount(totalBalance)} FCFA',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text("Comptes actifs", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final Map<String, IconData> typeIcons = {
      "Banque": Icons.account_balance_rounded,
      "Espèces": Icons.payments_rounded,
      "Épargne": Icons.savings_rounded,
    };

    final iconColor = account.type == "Banque" ? Colors.blue : (account.type == "Espèces" ? Colors.orange : Colors.teal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(_slideTransition(AccountDetailScreen(account: account))).then((_) => setState(() {}));
          },
          onLongPress: () => _showDeleteDialog(account),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(typeIcons[account.type] ?? Icons.credit_card_rounded, size: 26, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.type,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                      onPressed: () => _showAddOrEditAccountSheet(account: account),
                      splashRadius: 24,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Solde disponible', style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      '${_formatAmount(account.balance)} ${account.currencySymbol}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
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
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 12, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Text(
            widget.account != null ? 'Modifier le compte' : 'Nouveau compte',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: _buildInputDecoration('Nom du compte', Icons.drive_file_rename_outline),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            items: _accountTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
            decoration: _buildInputDecoration('Type de compte', Icons.account_tree_outlined),
            onChanged: (newValue) => setState(() => _selectedType = newValue!),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _buildInputDecoration('Solde initial', Icons.account_balance_wallet_outlined),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text;
              final balanceText = _balanceController.text.replaceAll(',', '.');
              final balance = double.tryParse(balanceText) ?? 0.0;
              if (name.isNotEmpty) {
                widget.onSave(widget.account, name, balance, _selectedType, _currencyController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              widget.account != null ? 'Mettre à jour' : 'Enregistrer le compte',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
