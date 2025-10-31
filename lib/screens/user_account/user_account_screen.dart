import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/user_account/change_pin_screen.dart';
import 'package:flutter/material.dart';

// --- Modèle de Données ---
class User {
  final int id;
  String name;
  String email;
  String phone;

  User({required this.id, required this.name, required this.email, required this.phone});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map[DbHelper.USER_ID],
      name: map[DbHelper.USER_NAME] ?? '',
      email: map[DbHelper.USER_EMAIL] ?? '',
      phone: map[DbHelper.USER_PHONE] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbHelper.USER_ID: id,
      DbHelper.USER_NAME: name,
      DbHelper.USER_EMAIL: email,
      DbHelper.USER_PHONE: phone,
      DbHelper.USER_UPDATED_AT: DateTime.now().toIso8601String(),
    };
  }
}

// --- Écran Principal ---
class UserAccountScreen extends StatefulWidget {
  const UserAccountScreen({super.key});

  @override
  State<UserAccountScreen> createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends State<UserAccountScreen> {

  Future<void> _updateUser(User user) async {
    await DbHelper.updateUser(user.toMap());
    setState(() {}); // Rafraîchit l'UI pour afficher les nouvelles données
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis à jour avec succès.'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditProfileSheet(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _EditProfileForm(user: user, onSave: _updateUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_circle), SizedBox(width: 8), Text('Mon Compte')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<User?>(
        future: DbHelper.getFirstUser(), // Méthode à créer dans DbHelper
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Aucun utilisateur trouvé."));
          }
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileCard(user),
                const SizedBox(height: 30),
                _buildActionButton(icon: Icons.edit, title: 'Modifier le profil', onTap: () => _showEditProfileSheet(user)),
                const SizedBox(height: 15),
                _buildActionButton(icon: Icons.lock, title: 'Changer le code PIN', onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChangePinScreen()));
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(radius: 50, backgroundColor: Colors.green.shade100, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '', style: const TextStyle(fontSize: 40, color: Colors.green))),
            const SizedBox(height: 15),
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.email_outlined, user.email),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.phone_outlined, user.phone),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, color: Colors.grey[600]), const SizedBox(width: 15), Text(text, style: const TextStyle(fontSize: 16))]);
  }

  Widget _buildActionButton({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

// --- Widget du Formulaire de Modification ---
class _EditProfileForm extends StatefulWidget {
  final User user;
  final Future<void> Function(User user) onSave;

  const _EditProfileForm({required this.user, required this.onSave});

  @override
  _EditProfileFormState createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Modifier le profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nom complet', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer un nom.' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Adresse e-mail', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer un e-mail.';
                if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                  return 'Veuillez entrer un e-mail valide.';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Téléphone', prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer un numéro.' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer les modifications'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.user.name = _nameController.text;
                  widget.user.email = _emailController.text;
                  widget.user.phone = _phoneController.text;
                  widget.onSave(widget.user);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}
