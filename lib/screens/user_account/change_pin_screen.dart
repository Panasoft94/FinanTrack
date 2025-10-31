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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _oldPinController,
                obscureText: !_oldPinVisible,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Ancien code PIN',
                  prefixIcon: const Icon(Icons.lock_open_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_oldPinVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _oldPinVisible = !_oldPinVisible),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) return 'Veuillez entrer un code à 6 chiffres.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPinController,
                obscureText: !_newPinVisible,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Nouveau code PIN',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                   suffixIcon: IconButton(
                    icon: Icon(_newPinVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _newPinVisible = !_newPinVisible),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) return 'Veuillez entrer un code à 6 chiffres.';
                  if (value == _oldPinController.text) return 'Le nouveau code PIN doit être différent.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPinController,
                obscureText: !_confirmPinVisible,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau PIN',
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                   suffixIcon: IconButton(
                    icon: Icon(_confirmPinVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _confirmPinVisible = !_confirmPinVisible),
                  ),
                ),
                validator: (value) {
                  if (value != _newPinController.text) return 'Les codes PIN ne correspondent pas.';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save_as_outlined),
                      label: const Text('Mettre à jour le code PIN'),
                      onPressed: _changePin,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
