import 'package:budget/screens/create_pin.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 100, color: Colors.green),
              const SizedBox(height: 40),
              const Text(
                'Bienvenue sur Finan Track',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Votre assistant personnel pour une gestion simple et efficace de votre budget au quotidien.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Couleur de fond
                  foregroundColor: Colors.white, // Couleur du texte
                  minimumSize: const Size(double.infinity, 50), // Largeur maximale
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const CreatePinPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Commencer', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
