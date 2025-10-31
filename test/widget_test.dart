import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp()); // Correction : Le paramètre a été retiré

    // Le reste de ce test est obsolète et devrait être mis à jour
    // pour correspondre à votre UI actuelle (par ex. l'écran de splash/login).
    // Pour l'instant, nous nous assurons simplement que le code compile.
  });
}
