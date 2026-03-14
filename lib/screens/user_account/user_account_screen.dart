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
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_circle), SizedBox(width: 8), Text('Mon Compte')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<User?>(
        future: DbHelper.getFirstUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Aucun utilisateur trouvé."));
          }
          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 30),
                _buildInfoSection(user),
                const SizedBox(height: 30),
                _buildActionSection(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: const Icon(Icons.camera_alt, size: 20, color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(user.email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildInfoSection(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoItem(Icons.person_outline, 'Nom complet', user.name),
          const Divider(height: 30),
          _buildInfoItem(Icons.email_outlined, 'Email', user.email),
          const Divider(height: 30),
          _buildInfoItem(Icons.phone_outlined, 'Téléphone', user.phone),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(User user) {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          title: 'Modifier le profil',
          subtitle: 'Mettre à jour vos informations',
          color: Colors.green,
          onTap: () => _showEditProfileSheet(user),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.lock_reset_outlined,
          title: 'Changer le code PIN',
          subtitle: 'Sécuriser votre accès',
          color: Colors.green,
          onTap: () => Navigator.of(context).push(_slideTransition(const ChangePinScreen())),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
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
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      padding: EdgeInsets.only(top: 10, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Text('Modifier le profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _buildTextField(controller: _nameController, label: 'Nom complet', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, label: 'Adresse e-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, label: 'Téléphone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.user.name = _nameController.text;
                    widget.user.email = _emailController.text;
                    widget.user.phone = _phoneController.text;
                    widget.onSave(widget.user);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green, width: 2)),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Ce champ est requis' : null,
    );
  }
}
