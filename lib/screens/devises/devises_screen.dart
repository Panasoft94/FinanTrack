import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';

// --- Modèle de Données ---
class Devise {
  int? id;
  String libelle;
  String valeur;
  String symbole;

  Devise({this.id, required this.libelle, required this.valeur, required this.symbole});

  factory Devise.fromMap(Map<String, dynamic> map) {
    return Devise(
      id: map[DbHelper.DEVISE_ID],
      libelle: map[DbHelper.DEVISE_LIB],
      valeur: map[DbHelper.DEVISE_VAL],
      symbole: map[DbHelper.DEVISE_SYMBOLE],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbHelper.DEVISE_ID: id,
      DbHelper.DEVISE_LIB: libelle,
      DbHelper.DEVISE_VAL: valeur,
      DbHelper.DEVISE_SYMBOLE: symbole,
    };
  }
}

// --- Écran Principal ---
class DevisesScreen extends StatefulWidget {
  const DevisesScreen({super.key});

  @override
  State<DevisesScreen> createState() => _DevisesScreenState();
}

class _DevisesScreenState extends State<DevisesScreen> {

  void _onSaveDevise(Devise? devise, String libelle, String valeur, String symbole) async {
    final newOrUpdatedDevise = Devise(id: devise?.id, libelle: libelle, valeur: valeur, symbole: symbole);
    final isEditing = devise != null;

    if (isEditing) {
      await DbHelper.updateDevise(newOrUpdatedDevise.toMap());
    } else {
      await DbHelper.insertDevise(newOrUpdatedDevise.toMap());
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Ferme le BottomSheet

    final message = isEditing ? 'Devise modifiée avec succès.' : 'Devise ajoutée avec succès.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {}); // Rafraîchit la liste
  }

  void _showAddOrEditDeviseSheet({Devise? devise}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddOrEditDeviseForm(devise: devise, onSave: _onSaveDevise),
    );
  }

  void _showDeleteDialog(Devise devise) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Text('Supprimer la devise')]),
              content: Text('Êtes-vous sûr de vouloir supprimer "${devise.libelle}" ?'),
              actionsAlignment: MainAxisAlignment.spaceAround,
              actions: [
                OutlinedButton(child: const Text('Annuler'), onPressed: () => Navigator.of(context).pop()),
                ElevatedButton(
                    child: const Text('Supprimer'),
                    onPressed: () async {
                      if (devise.id != null) {
                        await DbHelper.deleteDevise(devise.id!);
                      }
                      if (mounted) Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Devise "${devise.libelle}" supprimée.'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
                      );
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.currency_exchange), SizedBox(width: 8), Text('Gérer les devises')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Devise>>(
        future: DbHelper.getDevises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune devise trouvée.'));
          } else {
            final devises = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devises.length,
              itemBuilder: (context, index) {
                final devise = devises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24, // Augmente la taille du cercle
                      child: Text(
                        devise.symbole,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(devise.libelle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Valeur: ${devise.valeur}'),
                    trailing: IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () => _showAddOrEditDeviseSheet(devise: devise)),
                    onLongPress: () => _showDeleteDialog(devise),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddOrEditDeviseSheet, backgroundColor: Colors.green, foregroundColor: Colors.white, child: const Icon(Icons.add), tooltip: 'Ajouter une devise'),
    );
  }
}

// --- Widget du Formulaire ---
class _AddOrEditDeviseForm extends StatefulWidget {
  final Devise? devise;
  final Function(Devise? devise, String libelle, String valeur, String symbole) onSave;

  const _AddOrEditDeviseForm({this.devise, required this.onSave});

  @override
  _AddOrEditDeviseFormState createState() => _AddOrEditDeviseFormState();
}

class _AddOrEditDeviseFormState extends State<_AddOrEditDeviseForm> {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  final _valeurController = TextEditingController();
  final _symboleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.devise != null) {
      _libelleController.text = widget.devise!.libelle;
      _valeurController.text = widget.devise!.valeur;
      _symboleController.text = widget.devise!.symbole;
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _valeurController.dispose();
    _symboleController.dispose();
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
            Text(widget.devise != null ? 'Modifier la devise' : 'Nouvelle devise', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _libelleController, 
              decoration: InputDecoration(labelText: 'Libellé (ex: Franc CFA)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer un libellé.' : null,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _valeurController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Valeur', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer une valeur.' : null)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _symboleController, decoration: InputDecoration(labelText: 'Symbole (ex: €)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer un symbole.' : null)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave(widget.devise, _libelleController.text, _valeurController.text, _symboleController.text);
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
      ),
    );
  }
}
