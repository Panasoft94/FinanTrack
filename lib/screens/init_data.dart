import 'package:budget/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:budget/screens/database/db_helper.dart';

class InitDataScreen extends StatefulWidget {
  const InitDataScreen({super.key});

  @override
  State<InitDataScreen> createState() => _InitDataScreenState();
}

class _InitDataScreenState extends State<InitDataScreen> with TickerProviderStateMixin {
  double progress = 0.0;
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;

  final List<String> messages = [
    "Préparation de l'environnement...",
    "Création des tables...",
    "Configuration initiale...",
    "Ajout des données par défaut...",
    "Finalisation..."
  ];

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _buttonAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        progress = i / totalSteps;
      });
    }

    await DbHelper.getdb(); // Assure la création de la DB
    await DbHelper.insertDefaultConfig(); // Insère la config par défaut

    // Ajoute un compte par défaut si aucun n'existe
    final accounts = await DbHelper.getAccounts();
    if (accounts.isEmpty) {
      await DbHelper.insertAccount({
        'account_name': 'Compte defaut',
        'account_balance': 0.00,
        'account_type': 'Espèces', // Type de compte harmonisé
        'account_icon': 'FCFA', // Ajout du symbole de la devise
      });
    }

    if (mounted && progress == 1.0) {
      _buttonController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int messageIndex = (progress * messages.length).clamp(0, messages.length - 1).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.1).animate(CurvedAnimation(
                    parent: _logoController,
                    curve: Curves.easeInOut,
                  )),
                  child: const Icon(Icons.sync, size: 80, color: Colors.blueAccent),
                ),
                const SizedBox(height: 20),
                Text(messages[messageIndex], style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(value: progress),
                ),
                const SizedBox(height: 10),
                Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          if (progress == 1.0)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ScaleTransition(
                  scale: _buttonAnimation,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(child: Text("Initialisation terminée 👋 ")),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green.shade600,
                          showCloseIcon: true,
                          duration: const Duration(seconds: 2),
                          elevation: 6,
                        ),
                      );

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                            (route) => false,
                      );
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: const Icon(Icons.arrow_forward, key: ValueKey('arrow')),
                    ),
                    label: const Text("Tu peux aller →"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 4,
                    ),
                  )
                ),
              ),
            ),
        ],
      ),
    );
  }

}
