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

# Repertoires de cache persistables via volume
RUN mkdir -p /home/runner/.cache/Nuitka \
             /home/runner/.cache/pip \
             /home/runner/.cache/pyinstaller \
    && chown -R runner:runner /home/runner/.cache
