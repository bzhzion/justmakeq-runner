FROM myoung34/github-runner:ubuntu-jammy

# Image de runner GitHub Actions du parc bzhzion.
#
# ⛔ Elle s'appelait `justmakeq-runner` et ne portait que la chaine Qt/PyQt6/Nuitka de JustMakeQ.
# Elle servait pourtant deja a compiler les applications **Tauri** du parc, sans que rien ne le
# declare — ni son nom, ni son README, ni son changelog. Le 2026-09-25, un build de `hae-app` en
# Linux arm64 a compile Rust jusqu'au bout et est tombe a la toute derniere etape sur
# `xdg-mime binary not found`. Renommee `ci-runner` a cette occasion, et les outils manquants
# declares ici.
#
# ⚠️ **Deux chaines de compilation cohabitent volontairement** : Python/Qt/Nuitka pour JustMakeQ,
# Rust/GTK/WebKit pour Tauri. L'image est plus lourde pour tout le monde, c'est l'arbitrage pris :
# une seule image a tenir plutot que deux a garder en phase.

USER root

# System deps Qt/PyQt6 + outils Nuitka
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common curl \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.11 python3.11-dev python3.11-venv \
    libgl1 libglib2.0-0 libfontconfig1 \
    libxcb-xinerama0 libxkbcommon-x11-0 \
    patchelf ccache \
    && rm -rf /var/lib/apt/lists/*

# pip pour Python 3.11
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# python / python3 / pip -> 3.11
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && ln -sf /usr/local/bin/pip3.11 /usr/local/bin/pip

# Node.js LTS (npx wrangler)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Nuitka + deps de compilation pre-installes
RUN pip install --no-cache-dir nuitka ordered-set zstandard

# ── Chaine Tauri (Linux) ──────────────────────────────────────────────────────
#
# ⚠️ Cette liste n'est pas inventee : elle reprend EXACTEMENT ce que les workflows
# `release-linux*.yml` du parc installaient eux-memes a chaque build, plus `xdg-utils` qui y
# manquait. Les declarer ici les pose une fois pour toutes et evite un `apt-get` par execution.
#
# ⛔ `xdg-utils` est celui qui a coute un build : Tauri l'appelle a la toute derniere etape, pour
# enregistrer les types MIME de l'AppImage. Son absence ne se voit donc qu'apres la compilation
# complete de Rust — la panne arrive la ou l'on croit avoir fini.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential wget file \
    libwebkit2gtk-4.1-dev libgtk-3-dev \
    libayatana-appindicator3-dev librsvg2-dev \
    libxdo-dev libssl-dev \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Rust stable, installe a l'echelle du SYSTEME et non dans un `$HOME`.
#
# ⚠️ Les jobs s'executent sous l'utilisateur `runner`, pas sous root : un rustup pose dans
# `/root/.cargo` serait invisible pour eux. `CARGO_HOME` et `RUSTUP_HOME` sont donc places sous
# `/usr/local`, accessibles a tous, et le `PATH` est complete pour l'image entiere.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile minimal --no-modify-path \
    && chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME" \
    && rustc --version && cargo --version

# Repertoires de cache persistables via volume
RUN mkdir -p /home/runner/.cache/Nuitka \
             /home/runner/.cache/pip \
             /home/runner/.cache/pyinstaller \
    && chown -R runner:runner /home/runner/.cache
