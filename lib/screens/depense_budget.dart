
import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DepenseBudgetScreen extends StatefulWidget {
  final int categoryId;

  const DepenseBudgetScreen({Key? key, required this.categoryId}) : super(key: key);

  @override
  _DepenseBudgetScreenState createState() => _DepenseBudgetScreenState();
}

class _DepenseBudgetScreenState extends State<DepenseBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {required bool isStartDate}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner les dates de début et de fin.')),
        );
        return;
      }
      if (_startDate!.isAfter(_endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La date de début ne peut pas être après la date de fin.')),
        );
        return;
      }

      final budgetData = {
        'budget_name': _nameController.text,
        'budget_amount': double.parse(_amountController.text),
        'id': widget.categoryId, // Correction: la colonne de la base de données est 'id'
        'budget_start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'budget_end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'budget_status': 1, // 1 for active
      };

      DbHelper.insertBudget(budgetData).then((_) {
        final notificationData = {
          DbHelper.NOTIFICATION_TITRE: 'Budget créé',
          DbHelper.NOTIFICATION_CONTENU: 'Le budget \'${_nameController.text}\' a été créé avec succès.',
          DbHelper.NOTIFICATION_DATE: DateTime.now().toIso8601String(),
          DbHelper.NOTIFICATION_TYPE: 'success',
        };
        DbHelper.insertNotification(notificationData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget enregistré avec succès!')),
        );
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Définir un Budget'),
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
              Text(
                'Nouveau Budget',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du budget',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant du budget',
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
              const SizedBox(height: 20),
              const Text('Période du budget', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, isStartDate: true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date de début',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _startDate != null ? DateFormat.yMMMd().format(_startDate!) : 'Sélectionner',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, isStartDate: false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date de fin',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _endDate != null ? DateFormat.yMMMd().format(_endDate!) : 'Sélectionner',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer le Budget'),
                onPressed: _saveBudget,
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
