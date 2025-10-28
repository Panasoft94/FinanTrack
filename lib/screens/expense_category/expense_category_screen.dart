import 'package:flutter/material.dart';

class ExpenseCategoryScreen extends StatelessWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.category),
            SizedBox(width: 8),
            Text('Catégorie de dépenses'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Expense Category Screen'),
      ),
    );
  }
}
