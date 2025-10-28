import 'package:flutter/material.dart';

class BaseConfigScreen extends StatelessWidget {
  const BaseConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.settings_applications),
            SizedBox(width: 8),
            Text('Configuration de base'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Écran de configuration de base'),
      ),
    );
  }
}
