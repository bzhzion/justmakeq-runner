# justmakeq-runner

Image Docker GitHub Actions self-hosted runner.


## Ce qui est inclus

- Base : `myoung34/github-runner:ubuntu-focal`
- Python 3.11 (deadsnakes PPA)
- Deps systeme Qt/PyQt6 : `libgl1`, `libxcb-*`, `libxkbcommon-x11-0`, `patchelf`, `ccache`
- Node.js LTS (pour `npx wrangler`)
- `nuitka`, `ordered-set`, `zstandard`

## Deploiement

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
