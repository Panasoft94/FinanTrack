import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:budget/screens/login.dart';
import 'package:budget/screens/init_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool dbExists = await _checkDatabaseExists();
  runApp(MyApp(showInitScreen: !dbExists));
}

Future<bool> _checkDatabaseExists() async {
  final String path = join(await getDatabasesPath(), 'finantrack.db');
  return await databaseExists(path);
}

class MyApp extends StatelessWidget {
  final bool showInitScreen;
  const MyApp({super.key, required this.showInitScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: showInitScreen ? const InitDataScreen() : const LoginPage(),
    );
  }
}