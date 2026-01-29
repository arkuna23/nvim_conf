# Use a clean base image
FROM ubuntu:24.04

# --- 1. Basic Setup & Common Dependencies ---
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    sudo \
    lua5.4 \
    curl \
    wget \
    python3 \
    git \
    tar \
    unzip \
    npm \
    python3.12-venv \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# --- 2. User Setup ---
ARG UID=1000
ARG GID=1000

RUN (id -u ${UID} >/dev/null 2>&1 && userdel -f $(id -un ${UID}) || true) && \
    (getent group ${GID} >/dev/null 2>&1 && groupdel $(getent group ${GID} | cut -d: -f1) || true) && \
    groupadd -g ${GID} dev && \
    useradd -l -u ${UID} -g ${GID} -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dev
WORKDIR /home/dev/.config/nvim

# --- 3. Inject Scripts & Config ---
COPY --chown=dev:dev . .

ARG LANGS

# --- 4. Unified Execution & Cleanup ---
RUN mkdir -p lua && \
    if [ -z "$LANGS" ]; then \
    echo "return { editor_lang = nil }" > lua/user_config.lua; \
    else \
    formatted=$(echo "'${LANGS}'" | sed "s/,/','/g"); \
    echo "return { editor_lang = { ${formatted} } }" > lua/user_config.lua; \
    fi && \
    \
    bash install.sh && \
    \
    sudo apt-get autoremove -y && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER root
RUN chown -R dev:dev /home/dev/ && \
    sudo apt-get autoremove -y && \
    sudo apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER dev

RUN /usr/local/bin/nvim --headless \
    -c "TogglePluginsEnabled" \
    -S  lua/install_mason.lua \
    -c "qa"

WORKDIR /home/dev
CMD ["/bin/bash"]
