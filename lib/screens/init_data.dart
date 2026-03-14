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
        'account_name': 'Compte espèces',
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
      backgroundColor: Colors.grey[50],
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Eléments décoratifs en arrière-plan
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.1).animate(CurvedAnimation(
                        parent: _logoController,
                        curve: Curves.easeInOut,
                      )),
                      child: const Icon(Icons.auto_awesome_rounded, size: 80, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Initialisation",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      messages[messageIndex],
                      key: ValueKey(messages[messageIndex]),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  Container(
                    width: 250,
                    padding: const EdgeInsets.all(4),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (progress == 1.0)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: ScaleTransition(
                    scale: _buttonAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
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
                        icon: const Icon(Icons.rocket_launch_rounded, key: ValueKey('rocket'), color: Colors.white),
                        label: const Text(
                          "C'est parti !",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
