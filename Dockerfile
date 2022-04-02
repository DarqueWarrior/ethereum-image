# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.222.0/containers/debian/.devcontainer/base.Dockerfile

# user args
# some base images require specific values
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# [Choice] Debian version (use bullseye on local arm64/Apple Silicon): bullseye, buster
ARG VARIANT="bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

USER root
WORKDIR /home/vscode

ENV PATH $PATH:/home/vscode/.local/bin

###
# We intentionally create multiple layers so that they pull in parallel which improves startup time
###

RUN mkdir -p /home/vscode/.local/bin

# change ownership of the home directory
RUN chown -R vscode:vscode /home/vscode

RUN apt-get update && apt-get -yq install software-properties-common make g++ && \
    apt-get clean && apt-get autoclean

# ** [Optional] Uncomment this section to install additional packages. **
RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash - && \
    apt-get -yq install --no-install-recommends nodejs python3-venv python3-pip python3-dev && \
    apt-get autoclean -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN npm install --global --no-audit hardhat truffle ganache yarn && \
    npm cache clean --force

USER vscode

RUN python3 -m pip install pipx && \
    python3 -m pipx ensurepath && \
    python3 -m pip install eth-brownie && \
    python3 -m pip install vyper==0.2.16

USER root

# For brownie
# Files are copied to multiple locations to support use as Codespace, Docker Dev Environment, or 
# pure container
RUN wget https://solc-bin.ethereum.org/linux-amd64/solc-linux-amd64-v0.8.13+commit.abaa5c0e && \
    mkdir /root/.solcx && mv solc-linux-amd64-v0.8.13+commit.abaa5c0e /root/.solcx/solc-v0.8.13 && \
    chmod 755 /root/.solcx/solc-v0.8.13 && \
    mkdir -p /vscode/.solcx && cp /root/.solcx/solc-v0.8.13 /vscode/.solcx/solc-v0.8.13 && \
    mkdir -p /home/vscode/.solcx && cp /root/.solcx/solc-v0.8.13 /home/vscode/.solcx/solc-v0.8.13

# For brownie bake react
RUN wget https://github.com/vyperlang/vyper/releases/download/v0.2.16/vyper.0.2.16+commit.59e1bdd.linux && \
    mkdir /root/.vvm && mv vyper.0.2.16+commit.59e1bdd.linux /root/.vvm/vyper-0.2.16 && \
    chmod 755 /root/.vvm/vyper-0.2.16 && \
    mkdir -p /vscode/.vvm && cp /root/.vvm/vyper-0.2.16 /vscode/.vvm/vyper-0.2.16 && \
    mkdir -p /home/vscode/.vvm && cp /root/.vvm/vyper-0.2.16 /home/vscode/.vvm/vyper-0.2.16

RUN wget https://solc-bin.ethereum.org/linux-amd64/solc-linux-amd64-v0.6.12+commit.27d51765 && \
    mv solc-linux-amd64-v0.6.12+commit.27d51765 /root/.solcx/solc-v0.6.12 && \
    chmod 755 /root/.solcx/solc-v0.6.12 && \
    mkdir -p /vscode/.solcx && cp /root/.solcx/solc-v0.6.12 /vscode/.solcx/solc-v0.6.12 && \
    mkdir -p /home/vscode/.solcx && cp /root/.solcx/solc-v0.6.12 /home/vscode/.solcx/solc-v0.6.12

RUN echo 'deb http://ppa.launchpad.net/ethereum/ethereum/ubuntu bionic main' > /etc/apt/sources.list.d/ethereum.list && \
    echo 'deb-src http://ppa.launchpad.net/ethereum/ethereum/ubuntu bionic main' >> /etc/apt/sources.list.d/ethereum.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2A518C819BE37D2C2031944D1C52189C923F6CA9 && \
    apt-get update && \
    apt-get -yq install --no-install-recommends ethereum && \
    apt-get autoclean -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Setting up workspace folder for use with Docker Development Environments 
# without this
# folder you will get an error when you open in VSCode.
# https://github.com/docker/dev-environments/issues/98
RUN mkdir -p /com.docker.devenvironments.code/.vscode

RUN chown -R vscode:vscode /com.docker.devenvironments.code

# Copy extensions.json to prompt user to install the recommended vscode
# extensions when used with Docker Development Environments
COPY .vscode/*.* /com.docker.devenvironments.code/.vscode

# Removes warning from docker for desktop
RUN groupadd -r docker -g 433