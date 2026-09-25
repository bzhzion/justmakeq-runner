# Changelog

Toutes les évolutions notables de `justmakeq-runner` sont documentées ici.

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), versionnage
[SemVer](https://semver.org/lang/fr/). La section `[Unreleased]` accumule au fil de l'eau et
est renommée en numéro de version au moment de poser le tag.

Ce fichier est créé le 2026-09-05, après la mise en service : les évolutions antérieures ne sont
pas reconstituées, ce qui serait de la réécriture d'historique plutôt que de la documentation.
L'historique git reste la source de vérité pour ce qui précède.

## [0.2.0] - 2026-09-25

### Modifié

- ⛔ **Le dépôt et l'image sont renommés `justmakeq-runner` → `ci-runner`**
  (`ghcr.io/bzhzion/ci-runner`). Le nom laissait croire qu'ils ne servaient qu'à JustMakeQ alors
  qu'ils compilaient déjà les applications **Tauri** du parc, sans que leurs dépendances y soient
  déclarées. ⚠️ **L'ancien nom survit là où il désigne une ressource réelle** : les volumes
  `jmq-*-cache` (les renommer détacherait les caches existants) et le conteneur déployé sur
  oracle2 tant qu'il n'est pas recréé. Le changelog et l'historique git gardent l'ancien nom, ce
  sont des photos datées.

### Ajouté

- **La chaîne Tauri complète est déclarée dans l'image** : `build-essential`, `wget`, `file`,
  `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libayatana-appindicator3-dev`, `librsvg2-dev`,
  `libxdo-dev`, `libssl-dev`, `xdg-utils`, plus **Rust stable**. ⚠️ Cette liste n'est pas inventée :
  elle reprend ce que les workflows `release-linux*.yml` du parc installaient **eux-mêmes à chaque
  build**, plus `xdg-utils` qui y manquait. Les poser ici évite un `apt-get` par exécution.
- ⚠️ **Rust est installé sous `/usr/local`** (`CARGO_HOME`, `RUSTUP_HOME`) et non dans un `$HOME` :
  les jobs s'exécutent sous l'utilisateur `runner`, pas sous root, et un rustup posé dans
  `/root/.cargo` leur serait invisible.
- ⚠️ **Deux chaînes cohabitent désormais** (Python/Qt/Nuitka et Rust/GTK/WebKit). L'image est plus
  lourde pour tout le monde : c'est l'arbitrage pris, une seule image à tenir plutôt que deux à
  garder en phase.

- ⛔ **`xdg-utils`**, sans quoi l'empaquetage AppImage de Tauri échoue sur
  `xdg-mime binary not found`. Trouvé par un build réel de `hae-app` en Linux arm64 le 2026-09-25,
  qui compilait Rust jusqu'au bout et tombait à la **toute dernière étape**.
- ⚠️ **Ce que ça révèle, et qui dépasse le paquet** : cette image a été faite **pour JustMakeQ**
  (Qt/PyQt6/Nuitka/Python 3.11) et elle sert aussi à compiler les applications **Tauri** du parc.
  Rien ne le déclarait nulle part — ni son nom, ni son `README`, ni ce changelog. Une image
  réutilisée hors de son projet d'origine sans déclarer ses nouveaux besoins échoue sur la
  dépendance suivante, et le message désigne alors le projet qui compile, pas l'image qui manque.
- ⚠️ Le paquet n'est ajouté **qu'après avoir été prouvé manquant**. Les autres dépendances Tauri
  ne sont pas posées « au cas où » : si l'une manque, elle se verra au prochain build et s'ajoutera
  avec la trace de ce qui l'a exigée.

### Modifié

- **`actions/checkout` et `actions/setup-node` passent en v7** dans les workflows : les versions
  posées déclaraient `using: node20`, déprécié et déjà forcé sur Node 24 par GitHub. Les quatre
  changements de rupture de ces majeures ont été lus et confrontés au parc, aucun ne s'y applique,
  et les 11 runners de l'org sont en 2.336.0 ou mieux, au-dessus du minimum 2.327.1 qu'exigent
  `checkout` v5 et `setup-node` v5. Vérifié par un build iOS réel avant propagation.


### Corrigé

- **Le rebuild hebdomadaire ne mettait jamais vraiment à jour l'image.** `cache-from:
  type=gha` réutilise les couches, y compris celle de la base `myoung34/github-runner`,
  sans revalider son digest upstream tant que le `Dockerfile` ne change pas. Constaté le
  2026-09-24 : le runner `oracle2-linux-arm64` tournait sur une image de **juillet**
  malgré plusieurs rebuilds hebdomadaires "réussis" depuis, embarquant une version du
  runner GitHub Actions que GitHub avait entre-temps **dépréciée côté serveur**
  (déconnexion immédiate, `queued` indéfiniment côté job). Le cron et le déclenchement
  manuel avec `no_cache: true` ignorent désormais le cache.
- **Convention de fins de ligne du parc posée dans `.gitattributes`.** Le bloc `run:` d'un
  workflow GitHub Actions est un script shell exécuté sur un runner Linux : un antislash de
  continuation suivi d'un retour chariot **ne continue pas** la ligne, la commande est coupée en
  deux, et le message d'erreur ne parle jamais de fins de ligne.
- Cas réel du 2026-09-07 sur `bzhzion/cabanon` : un `.yml` recommité en CRLF depuis une machine
  Windows (où `core.autocrlf` est actif) a fait échouer le déploiement de l'API sur un
  `usage: ssh`, la destination de la commande ayant disparu avec la continuation.
- LF forcé sur ce qu'exécute Linux (`*.sh`, `*.yml`, `*.yaml`, `Dockerfile`), CRLF sur ce
  qu'exécute Windows (`*.ps1`, `*.bat`, `*.cmd`), et `* text=auto` comme filet général.
  Référence : `admin/.claude/gitattributes-parc`.


## [0.1.0] - 2026-09-05

### Modifié

- **Le déploiement ne part plus sur un push de branche, mais sur un tag `vX.Y.Z`.** Pousser un
  correctif de documentation ou une expérimentation sur `main` déclenchait jusqu'ici une livraison
  en production, ce qui va contre la règle du parc et rend toute modification du dépôt risquée.
  `workflow_dispatch` est conservé comme filet, ainsi que les crons de reconstruction et les
  déclencheurs de `pull_request`, qui sont des vérifications et non des livraisons.
- Volontairement **sans filtre de chemin** : GitHub combine (branches/tags) ET `paths`, ce qui rend
  un déclencheur sur tag imprévisible dès qu'un filtre de chemin subsiste.

### Ajouté

- **Convention changelog du parc posée sur ce dépôt** : ce fichier, les hooks `pre-commit` et
  `pre-push` dans `.githooks/`, et le workflow `changelog-guard.yml` qui rejoue les mêmes
  contrôles en CI au moment du tag. Ce dépôt en était dépourvu alors qu'il est déployé, ce qui
  le laissait hors de la garantie que les autres ont.

