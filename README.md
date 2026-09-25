# ci-runner

Image Docker du runner GitHub Actions self-hosted du parc bzhzion.

Elle porte **deux chaînes de compilation** qui cohabitent volontairement : Python/Qt/Nuitka pour
JustMakeQ, et Rust/GTK/WebKit pour les applications Tauri (Hae, Dictum, BeamMeUp, Hublot…).

> ⛔ **Ce dépôt s'appelait `justmakeq-runner` jusqu'au 2026-09-25.** Le nom laissait croire qu'il ne
> servait qu'à JustMakeQ, alors qu'il compilait déjà du Tauri — sans que ses dépendances y soient
> déclarées. Un build de `hae-app` en Linux arm64 a compilé Rust jusqu'au bout avant de tomber sur
> `xdg-mime binary not found`. **Une image réutilisée hors de son projet d'origine échoue sur la
> dépendance suivante, et le message accuse alors le projet qui compile, pas l'image qui manque.**

## Ce qui est inclus

**Base** : `myoung34/github-runner:ubuntu-jammy`

**Chaîne Python / Qt (JustMakeQ)**
- Python 3.11 (PPA deadsnakes), `pip` associé
- Dépendances système Qt/PyQt6 : `libgl1`, `libglib2.0-0`, `libfontconfig1`, `libxcb-xinerama0`,
  `libxkbcommon-x11-0`
- `patchelf`, `ccache`
- `nuitka`, `ordered-set`, `zstandard`

**Chaîne Rust / Tauri**
- Rust stable, installé à l'échelle du système (`/usr/local/cargo`, `/usr/local/rustup`)
- `build-essential`, `wget`, `file`
- `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`
- `libayatana-appindicator3-dev`, `librsvg2-dev`
- `libxdo-dev`, `libssl-dev`
- `xdg-utils`

**Commun**
- Node.js LTS (pour `npx wrangler`, `npm ci`…)

> ⚠️ **Rust est installé sous `/usr/local` et non dans un `$HOME`.** Les jobs s'exécutent sous
> l'utilisateur `runner`, pas sous root : un rustup posé dans `/root/.cargo` leur serait invisible.

> ⚠️ **La liste Tauri n'est pas inventée.** Elle reprend exactement ce que les workflows
> `release-linux*.yml` du parc installaient eux-mêmes à chaque build, plus `xdg-utils` qui y
> manquait. Les déclarer ici évite un `apt-get` par exécution.

## Déploiement

```bash
GITHUB_PAT=xxx docker compose up -d
```

Le `GITHUB_PAT` est un Personal Access Token GitHub avec le scope `repo`.

## Volumes persistants

| Volume | Chemin dans le container | Usage |
|--------|--------------------------|-------|
| `jmq-nuitka-cache` | `/home/runner/.cache/Nuitka` | Cache compilation Nuitka |
| `jmq-pip-cache` | `/home/runner/.cache/pip` | Cache pip |
| `jmq-pyinstaller-cache` | `/home/runner/.cache/pyinstaller` | Cache PyInstaller |

> ⚠️ Les volumes gardent le préfixe `jmq-` : ce sont des **ressources réelles déjà créées** sur la
> machine, les renommer détacherait les caches existants sans rien y gagner.
