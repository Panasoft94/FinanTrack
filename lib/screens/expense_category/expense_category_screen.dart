
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/depense_budget.dart';
import 'package:flutter/material.dart';

// --- Modèle de Données ---
class Category {
  int? id;
  String name;
  String type; // "expense" ou "income"
  IconData icon;
  Color color;

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  // Listes centralisées pour la consistance et pour résoudre l'erreur de tree-shaking
  static final List<IconData> availableIcons = [
    Icons.shopping_cart, Icons.fastfood, Icons.directions_car, Icons.movie,
    Icons.house, Icons.work, Icons.savings, Icons.receipt_long,
    Icons.medical_services, Icons.school, Icons.local_gas_station, Icons.phone_android,
    Icons.train, Icons.lightbulb_outline, Icons.pets, Icons.book,
  ];

  static final List<Color> availableColors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.cyan,
  ];

  // Trouve l'icône dans la liste au lieu de créer une nouvelle instance non-constante.
  static IconData _iconFromString(String iconString) {
    try {
      int codePoint = int.parse(iconString);
      return availableIcons.firstWhere(
        (icon) => icon.codePoint == codePoint,
        orElse: () => Icons.error_outline, // Icône de secours
      );
    } catch (e) {
      return Icons.error_outline; // Gère le cas où la conversion échoue
    }
  }

  static Color _colorFromString(String colorString) {
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.grey; // Couleur de secours
    }
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    final iconString = map['icon']?.toString();
    final colorString = map['color']?.toString();

    return Category(
      id: map['id'],
      name: map['name'] ?? 'Sans nom',
      type: map['type'] ?? 'expense',
      icon: iconString != null ? _iconFromString(iconString) : Icons.error_outline,
      color: colorString != null ? _colorFromString(colorString) : Colors.grey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon.codePoint.toString(),
      'color': color.value.toString(),
    };
  }
}

// --- Écran Principal ---
class ExpenseCategoryScreen extends StatefulWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  State<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState extends State<ExpenseCategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddOrEditCategorySheet({Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddOrEditCategoryForm(
        category: category,
        initialType: _tabController.index == 0 ? 'expense' : 'income',
        onSave: (cat) {
          final isEditing = cat.id != null;
          if (isEditing) {
            DbHelper.updateCategory(cat.toMap()).then((_) {
              setState(() {});
              Navigator.of(context).pop();
            });
          } else {
            DbHelper.insertCategory(cat.toMap()).then((newId) {
              setState(() {});
              Navigator.of(context).pop(); // Close the bottom sheet
              if (cat.type == 'expense') {
                // Navigate to budget screen only for expenses
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DepenseBudgetScreen(categoryId: newId),
                  ),
                );
              }
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.category), SizedBox(width: 8), Text('Catégories')],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_downward), SizedBox(width: 8), Text('DÉPENSES')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_upward), SizedBox(width: 8), Text('REVENUS')])),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(type: 'expense', onEdit: (cat) => _showAddOrEditCategorySheet(category: cat), onUpdate: () => setState(() {})),
          _CategoryList(type: 'income', onEdit: (cat) => _showAddOrEditCategorySheet(category: cat), onUpdate: () => setState(() {})),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditCategorySheet(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: _tabController.index == 0 ? 'Ajouter une catégorie de dépense' : 'Ajouter une catégorie de revenu',
      ),
    );
  }
}

// --- Widget affichant la liste des catégories ---
class _CategoryList extends StatelessWidget {
  final String type;
  final Function(Category) onEdit;
  final VoidCallback onUpdate;

  const _CategoryList({required this.type, required this.onEdit, required this.onUpdate});

  void _showDeleteDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Voulez-vous vraiment supprimer la catégorie "${category.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              DbHelper.deleteCategory(category.id!).then((_) {
                onUpdate();
                Navigator.of(context).pop();
              });
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: DbHelper.getCategories(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune catégorie pour le moment.'));
        }
        final categories = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onLongPress: () => _showDeleteDialog(context, category),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: category.color.withOpacity(0.2),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                  splashRadius: 24,
                  onPressed: () => onEdit(category),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Widget du Formulaire d'Ajout/Édition ---
class _AddOrEditCategoryForm extends StatefulWidget {
  final Category? category;
  final String initialType;
  final Function(Category) onSave;

  const _AddOrEditCategoryForm({this.category, required this.initialType, required this.onSave});

  @override
  __AddOrEditCategoryFormState createState() => __AddOrEditCategoryFormState();
}

class __AddOrEditCategoryFormState extends State<_AddOrEditCategoryForm> {
  final _nameController = TextEditingController();
  late String _type;
  late IconData _selectedIcon;
  late Color _selectedColor;

  final List<IconData> _icons = Category.availableIcons;
  final List<Color> _colors = Category.availableColors;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _type = widget.category!.type;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    } else {
      _nameController.text = '';
      _type = widget.initialType;
      _selectedIcon = _icons.first;
      _selectedColor = _colors.first;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category != null ? 'Modifier la catégorie' : 'Nouvelle catégorie', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Nom de la catégorie', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            
            if (widget.category == null)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Dépense'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'income', label: Text('Revenu'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_type},
                onSelectionChanged: (newSelection) => setState(() => _type = newSelection.first),
              ),
            const SizedBox(height: 20),

            const Text('Icône', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 10),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: CircleAvatar(
                      backgroundColor: _selectedIcon == icon ? Colors.green.withOpacity(0.2) : Colors.grey[200],
                      child: Icon(icon, color: _selectedIcon == icon ? Colors.green : Colors.grey[800]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            const Text('Couleur', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 10),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      backgroundColor: color,
                      child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final newCategory = Category(
                    id: widget.category?.id,
                    name: _nameController.text,
                    type: _type,
                    icon: _selectedIcon,
                    color: _selectedColor,
                  );
                  widget.onSave(newCategory);
                }
              },
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
    );
  }
}
