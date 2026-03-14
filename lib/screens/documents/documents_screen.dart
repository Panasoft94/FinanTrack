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
    categories.sort((a, b) => a.name.compareTo(b.name));
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.category_rounded, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Catégorie de la dépense",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Choisissez une catégorie pour trouver la transaction à justifier.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Aucune catégorie de dépense.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.circle, size: 12, color: Colors.green),
                          ),
                          title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(context);
                            _showTransactionSelection(context, category);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_shared_rounded),
            SizedBox(width: 12),
            Text(
              'Mes Documents',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            )
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.note_add_rounded, size: 80, color: Colors.green.withOpacity(0.2)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Aucun justificatif",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Conservez vos reçus et factures en les associant à vos transactions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }
          final documents = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final docId = doc[DbHelper.DOCUMENT_ID];
              final docName = doc[DbHelper.DOCUMENT_NAME];
              final docPath = doc[DbHelper.DOCUMENT_PATH];
              final transactionCount = doc['transactions'].length;
              final createdAt = doc[DbHelper.DOCUMENT_CREATED_AT];
              final extension = docName.split('.').last.toLowerCase();

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
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => OpenFilex.open(docPath),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildFileIcon(extension),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  docName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.link_rounded, size: 14, color: Colors.green[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$transactionCount associé(s)',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    if (createdAt != null) ...[
                                      const SizedBox(width: 12),
                                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd/MM/yy').format(DateTime.parse(createdAt)),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), shape: BoxShape.circle),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            ),
                            onPressed: () => _showDeleteConfirmationDialog(docId, docName),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySelection(context),
        backgroundColor: Colors.green,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("NOUVEAU DOCUMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFileIcon(String extension) {
    Color color;
    IconData icon;
    switch (extension) {
      case 'pdf':
        color = Colors.red[400]!;
        icon = Icons.picture_as_pdf_rounded;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        color = Colors.blue[400]!;
        icon = Icons.image_rounded;
        break;
      case 'doc':
      case 'docx':
        color = Colors.blue[700]!;
        icon = Icons.description_rounded;
        break;
      case 'xls':
      case 'xlsx':
        color = Colors.green[700]!;
        icon = Icons.table_chart_rounded;
        break;
      default:
        color = Colors.grey[400]!;
        icon = Icons.insert_drive_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
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
