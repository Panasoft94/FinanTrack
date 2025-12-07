import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.workspace_premium_outlined),
            SizedBox(width: 8),
            Text("Accès Premium"),
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
            children: [
              _buildPremiumHeader(context),
              const _PremiumFeature(
                icon: Icons.cloud_sync_outlined,
                title: 'Synchronisation Multi-Appareils',
                description: 'Accédez à vos données sur tous vos appareils, en temps réel.',
              ),
               const _PremiumFeature(
                icon: Icons.group_add_outlined,
                title: 'Gestion Multi-Utilisateur',
                description: 'Créez des profils familiaux, partagez des budgets et gérez les permissions pour une gestion collaborative.',
              ),
              const _PremiumFeature(
                icon: Icons.lightbulb_outline,
                title: 'Intelligence Budgétaire',
                description: 'Recevez des suggestions, simulez des scénarios et fixez-vous des objectifs d\'épargne avec un suivi visuel.',
              ),
              const _PremiumFeature(
                icon: Icons.palette_outlined,
                title: 'Thèmes & Personnalisation',
                description: 'Personnalisez l\'apparence de l\'application avec des thèmes exclusifs et des palettes de couleurs uniques.',
              ),
              const _PremiumFeature(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Exportations illimitées (PDF & CSV)',
                description: 'Générez des rapports détaillés et exportez-les pour vos archives ou votre comptable.',
              ),
              const _PremiumFeature(
                icon: Icons.auto_graph,
                title: 'Rapports et Analyses Avancés',
                description: 'Débloquez de nouveaux graphiques et des analyses de tendance pour mieux comprendre vos finances.',
              ),
              const _PremiumFeature(
                icon: Icons.repeat_on_outlined,
                title: 'Planification des Dépenses Récurrentes',
                description: 'Automatisez la saisie de vos dépenses fixes (loyer, abonnements) et ne perdez plus jamais de temps.',
              ),
              const _PremiumFeature(
                icon: Icons.alarm_on_outlined,
                title: 'Rappels Programmés',
                description: 'Recevez des notifications pour ne jamais oublier une facture, une échéance ou un renouvellement.',
              ),
              const _PremiumFeature(
                icon: Icons.calendar_month_outlined,
                title: 'Intégration Calendrier',
                description: 'Visualisez vos échéances et budgets directement dans votre calendrier personnel pour une vue d\'ensemble parfaite.',
              ),
              const _PremiumFeature(
                icon: Icons.cloud_upload_outlined,
                title: 'Sauvegardes Automatiques sur le Cloud',
                description: 'Ne perdez plus jamais vos données grâce à des sauvegardes automatiques et sécurisées.',
              ),
              const _PremiumFeature(
                icon: Icons.support_agent,
                title: 'Support Client Prioritaire',
                description: 'Obtenez des réponses rapides à toutes vos questions grâce à notre support dédié.',
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: const Text('Passer à Premium'),
                onPressed: () {
                  //  Logique pour l'achat à intégrer ici (ex: RevenueCat, in_app_purchase)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fonctionnalité d\'achat à venir !')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.verified_user_outlined, size: 100, color: Colors.green.withOpacity(0.8)),
        const SizedBox(height: 20),
        Text(
          'Passez au Niveau Supérieur',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Débloquez des fonctionnalités puissantes pour maîtriser pleinement votre budget.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(description, style: TextStyle(color: Colors.grey[700], height: 1.3)),
        ),
      ),
    );
  }
}
