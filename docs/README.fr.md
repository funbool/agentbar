<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · **🇫🇷 Français** · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Une application légère pour la barre de menus de macOS qui montre la part consommée de vos limites **Claude**, **Codex** et **Cursor** — avec des statistiques de tokens et ce que la même utilisation coûterait via les API publiques.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Fonctionnalités

- **Les limites en un coup d'œil** — fenêtres de 5 heures et hebdomadaires pour Claude et Codex, pools d'utilisation inclus pour Cursor, chacun avec une barre de progression, le temps restant avant réinitialisation et la date exacte.
- **Limites hebdomadaires par modèle** pour Claude (Opus, Sonnet, Fable, …) dès que l'API les fournit.
- **Statistiques d'utilisation** — tokens par type, coût, répartition par modèle et par projet, graphique quotidien ; Aujourd'hui / 7 jours / 30 jours / Tout.
- **Notifications** quand une limite dépasse un seuil, avec un seuil global et des règles par limite (couper, seuil personnalisé).
- **Actualisation automatique** en option, lancement à l'ouverture de session, 17 langues d'interface.
- **Mises à jour à distance** depuis GitHub Releases, vérifiées par SHA-256.
- **Aucun compte, aucune télémétrie.** AgentBar lit les jetons que les clients officiels stockent déjà sur votre Mac et ne parle qu'aux API des fournisseurs.

## Prérequis

- macOS 14 Sonoma ou plus récent (Apple Silicon ou Intel).
- Au moins un de ces clients, connecté : [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI ou application), [Cursor](https://cursor.com). Les fournisseurs inutilisés peuvent être masqués dans les réglages.

## Installation

1. Téléchargez `AgentBar.zip` depuis la [dernière release](https://github.com/funbool/agentbar/releases/latest).
2. Décompressez-le et déplacez `AgentBar.app` dans `/Applications`.
3. Ouvrez l'application. Elle s'ajoute aux éléments d'ouverture de session (désactivable dans les réglages).

**Gatekeeper.** Les releases sont signées ad hoc, non notariées. Si macOS refuse d'ouvrir une copie fraîchement téléchargée, faites un clic droit → *Ouvrir* une fois, ou retirez l'attribut de quarantaine :

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Demande du trousseau.** À la première actualisation de Claude, macOS demande si `security` peut lire l'élément *Claude Code-credentials*. Choisissez **Toujours autoriser**. La demande peut réapparaître après que Claude Code a renouvelé son jeton — c'est normal.

Vous pouvez aussi [compiler depuis les sources](#compiler-depuis-les-sources).

## Fonctionnement

AgentBar ne demande jamais de connexion. Il lit les identifiants que chaque client conserve déjà sur votre Mac et appelle les mêmes points d'accès que les clients.

| Fournisseur | Identifiants lus depuis | Point d'accès | Ce qui est affiché |
|---|---|---|---|
| Claude | Élément du trousseau `Claude Code-credentials` (lu via `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | Fenêtre de 5 h, fenêtre hebdomadaire, limites hebdomadaires par modèle |
| Codex | `~/.codex/auth.json` (ou `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | Fenêtre de 5 h, fenêtre hebdomadaire, forfait |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (lecture seule) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Pool des modèles Cursor (Auto / Composer / Grok), pool des modèles API, dépenses à la demande, Grok Bot hebdomadaire, montant dépensé sur le cycle |

AgentBar ne renouvelle pas les jetons. Si un fournisseur indique *session expirée*, ouvrez ce client une fois — il renouvellera le jeton et AgentBar le reprendra à l'actualisation suivante.

## Le panneau

- Cliquez sur l'icône de la barre de menus : tous les fournisseurs sont actualisés immédiatement ; les valeurs en cache restent visibles pendant le chargement.
- Les barres sont vertes sous 60 %, jaunes au-dessus, rouges dès que le seuil de notification est atteint.
- Chaque limite affiche le temps restant et l'instant exact de réinitialisation, par ex. *réinitialisation dans 2h 15m · jeu. 24 sept. 20:00*.
- La cloche à côté d'une limite ouvre sa règle de notification (on/off, seuil).
- Pied de panneau : statistiques · actualiser · réglages · quitter.

## Statistiques d'utilisation

Le bouton graphique du pied de panneau ouvre la fenêtre des statistiques. En haut, changez de fournisseur et de période ; survolez le graphique pour voir le total d'une journée ou la part d'un modèle.

| Fournisseur | Source | Coût |
|---|---|---|
| Claude | Transcriptions Claude Code (`~/.claude/projects/**/*.jsonl`), indexées une fois et mises en cache par fichier | Ce que la même utilisation coûterait via l'API : entrée/sortie au tarif public, écritures cache ×1,25 (TTL 5 min) / ×2 (TTL 1 h), lectures cache ×0,1 |
| Codex | Journaux de sessions (`~/.codex/sessions/**/*.jsonl`) | Tarifs publics de l'API OpenAI ; entrée en cache ×0,1. Les modèles sans prix public n'affichent que les tokens |
| Cursor | Événements d'utilisation du tableau de bord Cursor, mis en cache localement. À la première ouverture, vous choisissez de charger tout l'historique ou seulement le cycle de facturation en cours ; ensuite seuls les nouveaux événements sont récupérés | Tel que rapporté par Cursor pour chaque requête |

**Pourquoi les totaux Claude d'AgentBar diffèrent de `/stats` dans Claude Code.** Claude Code compte chaque ligne de transcription ; une réponse composée de plusieurs blocs (réflexion, texte, appels d'outils) est écrite sur plusieurs lignes partageant le même enregistrement d'utilisation, donc comptée plusieurs fois. AgentBar compte chaque réponse une seule fois avec les valeurs finales — ce que l'API facture réellement — et affiche le chiffre de Claude Code à côté, à titre de comparaison.

Indexer 700 Mo de transcriptions prend environ 10 secondes la première fois et bien moins d'une seconde ensuite. Les caches se trouvent dans `~/Library/Application Support/AgentBar/`.

## Notifications

- Activez les notifications dans Réglages → Notifications et choisissez un seuil par défaut (50–95 %).
- Chaque limite peut être coupée ou recevoir son propre seuil — depuis les réglages ou via la cloche du panneau.
- Vous recevez une notification par limite et par cycle de réinitialisation.
- Les limites sont vérifiées à chaque actualisation : selon la planification si l'actualisation automatique est active, sinon seulement à l'ouverture du panneau.

## Réglages

- **Général** — intervalle d'actualisation (désactivé / 1 / 5 / 15 / 30 / 60 min), fournisseurs visibles, langue, lancement à l'ouverture de session, mises à jour.
- **Notifications** — interrupteur global, seuil par défaut, règles par limite.

## Mises à jour

AgentBar consulte GitHub Releases une fois par jour et à chaque clic sur *Rechercher des mises à jour*. Lorsqu'une version plus récente existe, le panneau affiche un bouton *Mettre à jour*. La mise à jour est téléchargée, son SHA-256 est vérifié par rapport à la somme publiée, l'identifiant du bundle et la version sont contrôlés, l'ancienne application est placée dans la corbeille et la nouvelle est lancée. Toute release peut aussi être installée manuellement depuis la [page des releases](https://github.com/funbool/agentbar/releases).

## Compiler depuis les sources

Nécessite Xcode 15 ou plus récent (Swift 5.9). Aucune dépendance tierce.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # tests unitaires
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # compiler, copier dans /Applications et lancer
```

Outils de débogage (exécutez le binaire du bundle ou `.build/debug/AgentBar`) :

```bash
AgentBar --dump            # interroger chaque fournisseur une fois et afficher les limites analysées
AgentBar --raw             # afficher le JSON brut de chaque point d'accès
AgentBar --stats           # indexer les journaux locaux Claude/Codex et afficher les totaux
AgentBar --cursor-events   # récupérer les événements Cursor et afficher les totaux
AgentBar --update          # exécuter le cycle complet de mise à jour sans interface
```

### Publier une release

```bash
./scripts/release.sh 0.2.0
```

La commande incrémente la version dans `Packaging/Info.plist`, crée le tag `v0.2.0` et pousse. GitHub Actions exécute les tests, compile l'application, publie `AgentBar.zip` et `AgentBar.zip.sha256` en tant que release, et les copies en cours d'exécution la récupèrent à leur prochaine vérification.

## Confidentialité et sécurité

- **Lecture :** l'élément du trousseau de Claude Code, `~/.codex/auth.json`, le `state.vscdb` de Cursor (lecture seule), les transcriptions et journaux de sessions locaux.
- **Écriture :** préférences et caches dans `~/Library/Application Support/AgentBar/`.
- **Réseau :** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (vos propres données d'utilisation) et `api.github.com` / `github.com` (vérification et téléchargement des mises à jour). Rien d'autre.
- Les releases sont compilées par GitHub Actions à partir des sources taguées ; le workflow se trouve dans `.github/workflows/release.yml`.

## Dépannage

| Symptôme | Que faire |
|---|---|
| *Non connecté — ouvrez …* | Connectez-vous une fois à ce client ; AgentBar lira le jeton enregistré à l'actualisation suivante. |
| La demande du trousseau revient sans cesse | Choisissez *Toujours autoriser*. Une nouvelle demande après un certain temps signifie que Claude Code a renouvelé son jeton. |
| Cursor n'affiche rien | Ouvrez Cursor une fois pour qu'il renouvelle son jeton de session, puis actualisez AgentBar. |
| L'application ne s'ouvre pas après le téléchargement | Gatekeeper — voir [Installation](#installation). |
| Les statistiques restent sur *Indexation…* | La première indexation de gros dossiers de transcriptions prend du temps ; les exécutions suivantes utilisent le cache. |

## Remerciements

La recherche des points d'accès a été facilitée par le projet open source [CodexBar](https://github.com/steipete/CodexBar).

## Licence

[MIT](../LICENSE)
