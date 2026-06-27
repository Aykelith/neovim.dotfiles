FROM debian:bookworm-slim

ARG SCENARIO=nvim_missing

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Base tools needed to install Ansible + run playbooks
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip pipx curl wget git tar xz-utils sudo fontconfig \
    && rm -rf /var/lib/apt/lists/*

RUN pipx install ansible-core && pipx ensurepath
ENV PATH="/root/.local/bin:$PATH"

# Create the expected install dir skeleton
RUN mkdir -p /root/local-apps/nvim/bin

# Inject PATH entry so the PATH check passes by default
ENV PATH="/root/local-apps/nvim/bin:$PATH"

COPY packages.yml nvm.yml nvim.yml firacode.yml /playbooks/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV SCENARIO=${SCENARIO}
ENTRYPOINT ["/entrypoint.sh"]
