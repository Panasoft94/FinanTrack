import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/devises/devises_screen.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

// --- Modèle de Données ---
class Config {
  final int id;
  String appName;
  String defaultLanguage;
  int defaultYear;
  int selectedDeviseId;

  Config({
    required this.id,
    required this.appName,
    required this.defaultLanguage,
    required this.defaultYear,
    required this.selectedDeviseId,
  });

  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      id: map[DbHelper.CONFIG_ID],
      appName: map[DbHelper.APP_NAME] ?? 'Finan Track',
      defaultLanguage: map[DbHelper.DEFAULT_LANGUAGE] ?? 'Français',
      defaultYear: map[DbHelper.DEFAULT_YEAR] ?? DateTime.now().year,
      selectedDeviseId: int.tryParse(map[DbHelper.SELECTED_DEVISE_ID] ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbHelper.CONFIG_ID: id,
      DbHelper.APP_NAME: appName,
      DbHelper.DEFAULT_LANGUAGE: defaultLanguage,
      DbHelper.DEFAULT_YEAR: defaultYear,
      DbHelper.SELECTED_DEVISE_ID: selectedDeviseId.toString(),
    };
  }
}

// --- Écran Principal ---
class BaseConfigScreen extends StatefulWidget {
  const BaseConfigScreen({super.key});

  @override
  State<BaseConfigScreen> createState() => _BaseConfigScreenState();
}

class _BaseConfigScreenState extends State<BaseConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<dynamic>> _dataFuture;

  final _appNameController = TextEditingController();
  String? _selectedLanguage;
  int? _selectedYear;
  int? _selectedDeviseId;

  Config? _initialConfig;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([DbHelper.getFirstConfig(), DbHelper.getDevises()]);
  }

  // Charge les données dans les contrôleurs et variables d'état
  void _loadConfigData(Config config, List<Devise> devises) {
    _initialConfig ??= config; // Sauvegarde la config initiale une seule fois

    _appNameController.text = config.appName;
    _selectedLanguage = config.defaultLanguage;
    _selectedYear = config.defaultYear;

    if (devises.any((d) => d.id == config.selectedDeviseId)) {
      _selectedDeviseId = config.selectedDeviseId;
    } else if (devises.isNotEmpty) {
      _selectedDeviseId = devises.first.id;
    }
  }

  void _saveConfig() async {
    if (_formKey.currentState!.validate() && _initialConfig != null && _selectedDeviseId != null) {
      _initialConfig!.appName = _appNameController.text;
      _initialConfig!.defaultLanguage = _selectedLanguage!;
      _initialConfig!.defaultYear = _selectedYear!;
      _initialConfig!.selectedDeviseId = _selectedDeviseId!;

      await DbHelper.updateConfig(_initialConfig!.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Configuration enregistrée avec succès.'),
          backgroundColor: Colors.green[700],
        ));
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      // Recharge les données initiales depuis la copie sauvegardée
      if (_initialConfig != null) {
        _loadConfigData(_initialConfig!, []); // [] car la liste des devises n'a pas changé
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.settings_applications), SizedBox(width: 8), Text('Configuration de base')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _cancelEdit,
              tooltip: 'Annuler les modifications',
            )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data![0] == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "Erreur de chargement",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Impossible de récupérer la configuration.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final config = snapshot.data![0] as Config;
          final devises = snapshot.data![1] as List<Devise>;
          
          if (_initialConfig == null) { // Correction: Charger les données une seule fois
            _loadConfigData(config, devises);
          }

          // --- Validations défensives ---
          final List<String> languages = ['Français', 'English'];
          if (!languages.contains(_selectedLanguage)) {
            _selectedLanguage = languages.first;
          }

          final List<int> years = List.generate(5, (index) => DateTime.now().year - index);
          if (!years.contains(_selectedYear)) {
            _selectedYear = years.first;
          }

          return Form(
            key: _formKey,
            child: AbsorbPointer(
              absorbing: !_isEditing,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle(context, 'Général', Icons.tune),
                  const SizedBox(height: 10),
                  TextFormField(
                    readOnly: !_isEditing,
                    controller: _appNameController,
                    decoration: _buildInputDecoration('Nom de l\'application'),
                    validator: (value) => value!.isEmpty ? 'Ce champ est requis.' : null,
                  ),
                  const SizedBox(height: 30),

                  _buildSectionTitle(context, 'Internationalisation', Icons.language),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: _buildInputDecoration('Langue par défaut'),
                    items: languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                    onChanged: _isEditing ? (value) => setState(() => _selectedLanguage = value) : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField2<int>(
                    decoration: _buildInputDecoration('Devise par défaut'),
                    isExpanded: true,
                    value: _selectedDeviseId,
                    items: devises.map((devise) => DropdownMenuItem(value: devise.id, child: Text('${devise.libelle} (${devise.symbole})'))).toList(),
                    onChanged: _isEditing ? (value) => setState(() => _selectedDeviseId = value) : null,
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                      offset: const Offset(0, -5),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  _buildSectionTitle(context, 'Données', Icons.calendar_today),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: _buildInputDecoration('Année par défaut'),
                    items: years.map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
                    onChanged: _isEditing ? (value) => setState(() => _selectedYear = value) : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_isEditing) {
            _saveConfig();
          } else {
            setState(() => _isEditing = true);
          }
        },
        label: Text(_isEditing ? 'Enregistrer' : 'Modifier'),
        icon: Icon(_isEditing ? Icons.save : Icons.edit),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(children: [Icon(icon, color: Colors.grey[600]), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleLarge)]);
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label, 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
