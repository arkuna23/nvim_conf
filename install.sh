#!/usr/bin/env bash

ARCH_PACKAGES=(
    jq
    gitui
    rustup
    neovim
    ghcup-hs-bin
    stack
)

. /etc/os-release
if [ "$ID" = "arch" ]; then
    sudo pacman -S --needed -- "${ARCH_PACKAGES[@]}"
else
    echo "Distro not supported"
fi

