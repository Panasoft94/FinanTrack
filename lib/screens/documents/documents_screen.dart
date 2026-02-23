import 'dart:io';
import 'package:budget/screens/expense_category/expense_category_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<Map<String, dynamic>>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    setState(() {
      _documentsFuture = DbHelper.getDocumentsWithTransactions();
    });
  }

  void _showCategorySelection(BuildContext context) async {
    final categories = await DbHelper.getCategories('expense');
    categories.sort((a, b) => a.name.compareTo(b.name)); // Tri alphabétique
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        if (categories.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Aucune catégorie de dépense à afficher.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Sélectionner une catégorie",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(category.name),
                    onTap: () {
                      Navigator.pop(context);
                      _showTransactionSelection(context, category);
                    },
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1), // Séparateur
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionSelection(
      BuildContext context, Category category) async {
    final transactions = await DbHelper.getTransactionsByCategory(category.id!);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: TransactionSelectionSheet(
            transactions: transactions,
            category: category,
            onDocumentsSaved: _loadDocuments,
          ),
        );
      },
    );
  }

  Future<void> _deleteDocument(int docId) async {
    await DbHelper.deleteDocument(docId);
    _loadDocuments();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document supprimé avec succès.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteConfirmationDialog(int docId, String docName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer le document "$docName" ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDocument(docId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.file_copy_outlined), SizedBox(width: 8), Text('Documents')]),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.find_in_page_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "Aucun document justificatif",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Appuyez sur le bouton + pour en ajouter un.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          final documents = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80), // Add padding for FAB
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final docId = doc[DbHelper.DOCUMENT_ID];
              final docName = doc[DbHelper.DOCUMENT_NAME];
              final docPath = doc[DbHelper.DOCUMENT_PATH];
              final transactionCount = doc['transactions'].length;
              final createdAt = doc[DbHelper.DOCUMENT_CREATED_AT];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => OpenFilex.open(docPath),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.0),
                          child: Divider(),
                        ),
                        Row(
                          children: [
                            Icon(Icons.link, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Associé à $transactionCount transaction(s)',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(docId, docName),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Supprimer le document',
                            ),
                          ],
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Ajouté le ${DateFormat.yMd('fr_FR').format(DateTime.parse(createdAt))}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategorySelection(context),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        tooltip: 'Ajouter un document',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TransactionSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final Category category;
  final VoidCallback onDocumentsSaved;

  const TransactionSelectionSheet(
      {super.key,
      required this.transactions,
      required this.category,
      required this.onDocumentsSaved});

  @override
  _TransactionSelectionSheetState createState() =>
      _TransactionSelectionSheetState();
}

class _TransactionSelectionSheetState extends State<TransactionSelectionSheet> {
  final Map<int, bool> _selectedTransactions = {};
  String _searchQuery = '';

  void _pickAndSaveDocument() async {
    final selectedIds = _selectedTransactions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner au moins une transaction.')),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx', 'xls', 'xlsx'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      final docData = {
        DbHelper.DOCUMENT_NAME: (file.name.lastIndexOf('.') != -1)
            ? '${file.name.substring(0, file.name.lastIndexOf('.'))}.${file.extension?.toLowerCase() ?? ''}'
            : file.name,
        DbHelper.DOCUMENT_PATH: file.path!,
        DbHelper.DOCUMENT_TYPE: file.extension?.toLowerCase() ?? 'unknown',
        DbHelper.CATEGORY_ID: widget.category.id,
      };

      await DbHelper.insertDocument(docData, selectedIds);

      if (mounted) Navigator.pop(context);
      widget.onDocumentsSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document enregistré avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = widget.transactions.where((t) {
      final description = t['transaction_description']?.toString().toLowerCase() ?? '';
      final amount = t['montant']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return description.contains(query) || amount.contains(query);
    }).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sélectionner les transactions'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Column(
          children: [
             Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text('Catégorie: "${widget.category.name}"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une transaction...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: filteredTransactions.isEmpty
                  ? const Center(child: Text('Aucune transaction pour cette catégorie.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        final transactionId = transaction['transaction_id'] as int;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 2,
                           shape: RoundedRectangleBorder(
                            side: BorderSide(color: (_selectedTransactions[transactionId] ?? false) ? Colors.green : Colors.transparent, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            title: Text(transaction['transaction_description'] ?? 'Sans description', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                                '${NumberFormat.decimalPattern('fr_FR').format(transaction['montant'])} FCFA - ${DateFormat.yMd('fr_FR').format(DateTime.parse(transaction['transaction_date']))}'),
                            value: _selectedTransactions[transactionId] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                _selectedTransactions[transactionId] = value!;
                              });
                            },
                            activeColor: Colors.green,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.attach_file_outlined),
                label: const Text('Joindre un document'),
                onPressed: _pickAndSaveDocument,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
