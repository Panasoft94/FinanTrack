import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isSaving = false;
  bool _oldPinVisible = false;
  bool _newPinVisible = false;
  bool _confirmPinVisible = false;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final success = await DbHelper.updateUserPin(
        _oldPinController.text,
        _newPinController.text,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Code PIN modifié avec succès !'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('L\'ancien code PIN est incorrect.'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 8),
            Text('Changer le code PIN'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderIcon(),
              const SizedBox(height: 32),
              _buildInstructionText(),
              const SizedBox(height: 32),
              _buildPinField(
                controller: _oldPinController,
                label: 'Ancien code PIN',
                isVisible: _oldPinVisible,
                onVisibilityToggle: () => setState(() => _oldPinVisible = !_oldPinVisible),
                icon: Icons.lock_open_outlined,
              ),
              const SizedBox(height: 16),
              _buildPinField(
                controller: _newPinController,
                label: 'Nouveau code PIN',
                isVisible: _newPinVisible,
                onVisibilityToggle: () => setState(() => _newPinVisible = !_newPinVisible),
                icon: Icons.lock_outline,
                validator: (value) {
                  if (value == null || value.length != 6) return 'Veuillez entrer 6 chiffres.';
                  if (value == _oldPinController.text) return 'Doit être différent de l\'ancien.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPinField(
                controller: _confirmPinController,
                label: 'Confirmer le nouveau PIN',
                isVisible: _confirmPinVisible,
                onVisibilityToggle: () => setState(() => _confirmPinVisible = !_confirmPinVisible),
                icon: Icons.lock_person_outlined,
                validator: (value) {
                  if (value != _newPinController.text) return 'Les codes ne correspondent pas.';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              _isSaving
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : ElevatedButton(
                      onPressed: _changePin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Mettre à jour le code PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.shield_outlined, size: 64, color: Colors.green),
      ),
    );
  }

  Widget _buildInstructionText() {
    return Column(
      children: [
        const Text('Sécurisez votre compte', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text(
          'Votre code PIN doit être composé de 6 chiffres pour garantir la sécurité de vos données financières.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: const TextStyle(letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onVisibilityToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator ?? (value) => (value == null || value.length != 6) ? 'Veuillez entrer 6 chiffres.' : null,
    );
  }
}
