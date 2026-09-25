FROM myoung34/github-runner:ubuntu-jammy

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

# Dependances de l'empaquetage Tauri (AppImage).
#
# ⛔ Cette image a ete faite POUR JustMakeQ (Qt/PyQt6/Nuitka), et elle sert aussi a compiler les
# applications Tauri du parc — dont `hae-app` en Linux arm64. Rien ne le declarait, d'ou l'echec du
# 2026-09-25 : la compilation Rust passait, et le build tombait a la toute derniere etape sur
# `xdg-mime binary not found`, `xdg-utils` n'etant pas installe.
#
# ⚠️ Le paquet n'est ajoute qu'apres avoir ete PROUVE manquant par un build reel. Les autres
# dependances Tauri ne sont pas posees « au cas ou » : si l'une manque, elle se verra au prochain
# build et s'ajoutera ici, avec la trace de ce qui l'a exigee.
RUN apt-get update && apt-get install -y --no-install-recommends \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Repertoires de cache persistables via volume
RUN mkdir -p /home/runner/.cache/Nuitka \
             /home/runner/.cache/pip \
             /home/runner/.cache/pyinstaller \
    && chown -R runner:runner /home/runner/.cache
