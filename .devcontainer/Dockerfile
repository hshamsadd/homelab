FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG TARGETARCH

RUN apt-get update && apt-get install -y \
    curl ca-certificates gnupg git wget jq yq vim nano bash-completion \
    postgresql-client dnsutils iputils-ping netcat-openbsd eza bat unzip \
    ripgrep fd-find fzf tree less htop tmux \
    build-essential python3 python3-pip python3-venv nodejs npm \
    luarocks lua5.4 \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

# RUN curl -Lo /usr/local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage \
#    && chmod +x /usr/local/bin/nvim

RUN curl -Lo /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    && tar -C /opt -xzf /tmp/nvim.tar.gz \
    && ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
    && rm /tmp/nvim.tar.gz

RUN curl -LO "https://dl.k8s.io/release/v1.35.5/bin/linux/${TARGETARCH}/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/kustomize

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN curl -Lo /usr/local/bin/mc "https://dl.min.io/client/mc/release/linux-${TARGETARCH}/mc" \
    && chmod +x /usr/local/bin/mc

USER vscode

RUN git clone https://github.com/LazyVim/starter ~/.config/nvim \
    && rm -rf ~/.config/nvim/.git

WORKDIR /workspaces/homelab

# Nerd Font (JetBrainsMono Nerd Font)