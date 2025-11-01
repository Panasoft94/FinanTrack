import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text("Guide d'utilisation"),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: const [
              _GuideSection(
                icon: Icons.swap_horiz,
                title: 'Gérer les Transactions',
                description:
                    "Ajoutez, modifiez ou supprimez vos dépenses et revenus. Un appui long sur une transaction permet de la supprimer. Utilisez l\'icône de recherche pour filtrer vos opérations par description, catégorie ou compte.",
              ),
              _GuideSection(
                icon: Icons.account_balance_wallet,
                title: 'Gérer les Comptes',
                description:
                    "Créez différents comptes (ex: Espèces, Compte bancaire) pour suivre vos soldes. Chaque transaction affecte le solde du compte associé.",
              ),
              _GuideSection(
                icon: Icons.inventory_2,
                title: 'Suivre les Budgets',
                description:
                    "Définissez des budgets mensuels pour vos catégories de dépenses. Suivez votre consommation en temps réel grâce aux barres de progression et activez ou désactivez un budget depuis sa page de détail.",
              ),
              _GuideSection(
                icon: Icons.pie_chart,
                title: 'Analyser les Rapports',
                description:
                    "Visualisez un résumé de vos finances. Filtrez par date, analysez la répartition de vos dépenses par catégorie avec le graphique circulaire et suivez l\'évolution de vos dépenses avec la courbe de tendance.",
              ),
              _GuideSection(
                icon: Icons.settings,
                title: 'Configurer l\'application',
                description:
                    "Personnalisez votre expérience dans les paramètres. Vous pouvez sauvegarder vos données dans un fichier, restaurer une sauvegarde précédente ou réinitialiser certaines parties de l'application.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: Colors.green),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
