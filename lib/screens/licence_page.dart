import 'package:flutter/material.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/login.dart';

class LicencePage extends StatefulWidget {
  // final VoidCallback onAccepted; // REMOVED
  final int usersId;

  const LicencePage({
    Key? key,
    // required this.onAccepted, // REMOVED
    required this.usersId
  }) : super(key: key);

  @override
  State<LicencePage> createState() => _LicencePageState();
}

class _LicencePageState extends State<LicencePage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToEnd = false;
  bool _isChecked = false;

  void _checkScrollPosition() {
    if (_scrollController.position.maxScrollExtent - _scrollController.offset < 50) {
      if (!_hasScrolledToEnd) {
        setState(() {
          _hasScrolledToEnd = true;
        });
      }
    }
  }

  Future<void> _updateUserLicence() async { // Future<void> est plus précis ici
    final int aceptedLicence = 1;
    await DbHelper.updateLicence(widget.usersId, aceptedLicence);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(false); 
        return true; 
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 6,
          toolbarHeight: 65,
          backgroundColor: Colors.green,
          title: const Text(
            "Conditions d'utilisation",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Text(
                      _licenseText,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _hasScrolledToEnd ? 1.0 : 0.3,
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text("J'ai lu et j'accepte les termes du contrat"),
                    value: _isChecked,
                    onChanged: _hasScrolledToEnd
                        ? (val) => setState(() => _isChecked = val ?? false)
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text("Continuer", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: () async { // MODIFIÉ: devient async
                        if (_isChecked && _hasScrolledToEnd) {
                          print("LICENCE_PAGE: Conditions met. Attempting to update licence..."); // DEBUG
                          try {
                            await _updateUserLicence(); // MODIFIÉ: await l'appel
                            print("LICENCE_PAGE: Licence updated. Popping with true."); // DEBUG
                            if (mounted) Navigator.of(context).pop(true);
                          } catch (e) {
                            print("LICENCE_PAGE: Error updating licence: $e. Popping with false."); // DEBUG
                            if (mounted) Navigator.of(context).pop(false);
                            if (mounted) { 
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Erreur lors de l'acceptation de la licence.", style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else if (!_hasScrolledToEnd) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Veuillez lire l'intégralité des termes.", style: TextStyle(color: Colors.white)),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.blue,
                            ),
                          );
                        } else { // _isChecked is false
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Veuillez accepter les termes avant de continuer !", style: TextStyle(color: Colors.white)),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  final String _licenseText = '''
  ------------------------------------------------------------------------
                PANASOFT CORPORATION - RCA 
  ------------------------------------------------------------------------
  
Bienvenue sur FinanTrack .
 En utilisant cette application, vous acceptez les conditions suivantes :

1. Utilisation responsable
2. Protection des données
3. Respect de la propriété intellectuelle
4. Limitation de responsabilité
5. Mises à jour et modifications
6. Contact et support

Veuillez lire attentivement ces conditions avant de continuer.

1. Utilisation responsable:

L’utilisateur s’engage à utiliser l’application de manière conforme aux lois en vigueur, aux bonnes pratiques numériques et au respect des autres membres. En particulier, il est interdit de :

- Utiliser l’application à des fins frauduleuses, illégales ou contraires à l’ordre public.

- Transmettre des données fausses, trompeuses ou non autorisées.

- Accéder ou tenter d’accéder aux données d’autres utilisateurs sans autorisation.

- Perturber le bon fonctionnement de l’application par des actions malveillantes (ex. : injection SQL, spam, surcharge du serveur).

- Reproduire, copier ou redistribuer tout contenu de l’application sans autorisation préalable.

L’utilisateur est responsable de la sécurité de son compte et de ses actions dans l’application. En cas de non-respect, PANASOFT se réserve le droit de suspendre ou supprimer l’accès à l’application sans préavis.

2. 🔐 Protection des données:

Nous accordons une grande importance à la confidentialité et à la sécurité des informations personnelles. À ce titre :
- Collecte minimale : seules les données strictement nécessaires au bon fonctionnement de l’application sont collectées.

- Consentement explicite : l’utilisateur est informé et doit accepter les conditions avant toute collecte ou traitement.

- Stockage sécurisé : les données sont stockées localement ou sur des serveurs sécurisés, avec des mesures de protection contre les accès non autorisés.

- Accès restreint : seules les personnes ou systèmes autorisés peuvent accéder aux données, dans le cadre strict de leur usage prévu.

- Aucune revente : les données ne sont jamais vendues, louées ou partagées à des tiers sans consentement.

- Droit de suppression : l’utilisateur peut à tout moment demander la suppression de ses données personnelles.


3. 📚 Respect de la propriété intellectuelle:

L’utilisateur s’engage à respecter les droits de propriété intellectuelle relatifs à l’application et à son contenu. Cela inclut, sans s’y limiter :

- Code source, design, textes, icônes, illustrations et bases de données : protégés par le droit d’auteur et ne peuvent être copiés, modifiés ou réutilisés sans autorisation.

- Contenus tiers intégrés (ex. : polices, bibliothèques, API) : soumis à leurs propres licences, que l’utilisateur s’engage à respecter.

- Marques et logos : ne peuvent être utilisés sans accord préalable de leur titulaire.

- Contributions de l’utilisateur : doivent être originales ou utilisées avec autorisation. L’utilisateur garantit qu’il détient les droits nécessaires.

Toute violation peut entraîner la suspension du compte, des poursuites ou la suppression des contenus concernés.


4. ⚖️ Limitation de responsabilité:

L’application est fournie « telle quelle », sans garantie explicite ou implicite. En utilisant l’application, 
l’utilisateur accepte les limitations suivantes :

- Fiabilité des données : bien que nous nous efforcions d’assurer l’exactitude des informations, des erreurs ou omissions peuvent survenir. L’utilisateur reste seul responsable de l’usage qu’il fait des données affichées.

- Disponibilité du service : l’accès à l’application peut être temporairement interrompu pour maintenance, mise à jour ou en cas de force majeure. Aucune garantie de disponibilité continue n’est fournie.

- Sécurité : malgré les mesures mises en place, aucun système n’est invulnérable. Nous ne pouvons être tenus responsables en cas d’accès non autorisé, perte ou altération de données.

- Responsabilité limitée : en aucun cas PANASOFT ne pourra être tenue responsable des dommages directs ou indirects liés à l\'utilisation de l\'application, y compris des problèmes techniques ou de sécurité.


5. 🔄 Mises à jour et modification:

 L\'éditeur de l\'application se réserve le droit d\'apporter des modifications à tout moment, 
 notamment :
 
 - Fonctionnalités : ajout, suppression ou modification de modules, interfaces ou services.
 
 - Conditions d\'utilisation : révision des termes pour refléter l’évolution légale, technique ou fonctionnelle.
 
 - Politique de confidentialité : mise à jour des pratiques de collecte, traitement ou stockage des données.
 
   Ces changements peuvent être communiqués via l\'application, par notification ou lors de  la prochaine connexion .L\'utilisation continue de l\'application après modification vaut acceptation des nouvelles conditions.

📬 Contact et support:

Pour toute question, suggestion ou problème technique,l\'utilisateur peut contacter l\'équipe de support à l\'adresse suivante :

- 📧 Email : webmasterdjim@gmail.com

- 📞 Téléphone : +236 72 39 59 35 (du lundi au vendredi, 9h–17h)

- 📄 Formulaire de contact : disponible sur notre site web www.panasoft-ca.com/contact

Nous nous engageons à répondre dans un délai raisonnable et à traiter chaque demande avec sérieux et confidentialité


FIN DES TERMES ET CONDITIONS.

____________________________________________
''';
}
