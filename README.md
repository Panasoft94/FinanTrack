# 📱 FinanTrack

**FinanTrack** est une application mobile de gestion de budget familial développée en **Flutter** avec une base de données locale **SQLite**. Elle permet de suivre les revenus, les dépenses, les comptes et les objectifs financiers de manière intuitive, sécurisée et totalement hors-ligne.

---

## 🚀 Fonctionnalités principales

- 📊 **Tableau de bord interactif** : vue synthétique du solde, des dépenses et revenus
- 💰 **Gestion multi-comptes** : espèces, banque, mobile money, etc.
- 🧾 **Transactions catégorisées** : avec pièces jointes, notes et récurrence.
- 💡 **Saisie Intelligente** : dictionnaire de descriptions avec autocomplétion animée pour accélérer la saisie des transactions.
- 📉 **Analyses Avancées** : statistiques mensuelles avec design moderne, gradients et graphiques circulaires pour visualiser la répartition des dépenses.
- 🎯 **Budgets par catégorie** : suivi visuel et alertes de dépassement
- 📂 **Gestion des documents** : associez des reçus, factures et autres justificatifs à vos transactions.
- 📅 **Calendrier financier** : rappels de paiements et vue mensuelle
- 📈 **Statistiques et rapports** : graphiques dynamiques, filtres, export CSV/PDF
- 👨‍👩‍👧‍👦 **Multi-utilisateur local** : profils familiaux avec rôles et permissions
- 🔐 **Sécurité intégrée** : verrouillage par code PIN ou biométrie

---

## 🧱 Stack technique

| Technologie | Usage |
|-------------|-------|
| Flutter     | UI/UX multiplateforme (Android/iOS) |
| SQLite      | Base de données locale embarquée |
| Provider / Riverpod | Gestion d’état (selon implémentation) |
| Path / Sqflite | Accès aux fichiers et à la base |
| Charts_flutter / fl_chart | Visualisation des données |
| SharedPreferences | Stockage local léger (thème, préférences) |
| Intl        | Internationalisation et formatage des devises |

---

## ✨ Dernières Améliorations

### 🧠 Dictionnaire de descriptions (Auto-complétion)
Une nouvelle table `dictionnaires` a été ajoutée pour stocker automatiquement les descriptions de transactions. 
- **Migration sécurisée** : Passage à la version 6 de la base de données SQLite sans perte de données.
- **Expérience Utilisateur** : Suggestions intelligentes avec animations fluides lors de la saisie.
- **Logique intelligente** : Les doublons sont automatiquement filtrés pour garder un dictionnaire propre.

### 🎨 Refonte de l'Interface Statistiques & Transactions
L'expérience utilisateur a été modernisée sur plusieurs écrans clés avec un design "Material 3 / Neumorphic" :
- **Transactions & Analytique** : Nouveau système d'onglets séparant le journal des transactions de l'analyse des tendances hebdomadaires via `fl_chart`.
- **Saisie de Transaction** : BottomSheet modernisé avec toggle dynamique (Dépense/Revenu) et champs de saisie stylisés.
- **Budgets** : Amélioration de la visibilité avec un espacement intelligent pour éviter que le bouton flottant ne masque les données. Export PDF intégré pour les rapports de budget.
- **Paramètres & Compte** : Organisation logique par sections (Général, Outils, Données) avec des tuiles interactives et icônes colorées.
- **Sécurité** : Refonte de l'interface de changement de code PIN pour une meilleure lisibilité.

### 📈 Visualisation de Données (Tendances)
- Intégration de graphiques de tendances hebdomadaires comparant les revenus et les dépenses.
- Tooltips interactifs pour explorer les montants point par point sur la courbe.
- Résumé analytique automatique de la semaine pour une prise de décision rapide.

---

## 🗂️ Structure du projet
