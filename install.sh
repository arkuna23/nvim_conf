#!/usr/bin/env bash

mkdir -p lua
[ ! -f "lua/user_config.lua" ] && echo "return {}" >"lua/user_config.lua"

# --- Environment Setup ---
export LUA_PATH="./lua/?.lua;./lua/?/init.lua;;"
ENTRY="install.lua"

# --- Distro Detection ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Error: Cannot detect OS distribution."
    exit 1
fi

# --- Function: Install Lua if missing ---
bootstrap_lua() {
    echo "Lua missing. Installing for $ID..."
    case "$ID" in
    "arch") sudo pacman -Sy --needed --noconfirm lua ;;
    "debian" | "ubuntu") sudo apt-get update && sudo apt-get install -y lua5.4 ;;
    *)
        echo "Unsupported OS: $ID"
        exit 1
        ;;
    esac
}

# --- Runtime Detection ---
RUNTIME=$(command -v luajit || command -v lua || command -v lua5.4)

if [ -z "$RUNTIME" ]; then
    if command -v nvim &>/dev/null; then
        RUNTIME="nvim -l"
    else
        bootstrap_lua
        RUNTIME=$(command -v lua || command -v lua5.4)
    fi
fi

# --- Execute Lua ---
# We pass $ID as the FIRST argument, followed by all other original arguments ($@)
echo "Launching $ENTRY for $ID..."
$RUNTIME "$ENTRY" "$ID" "$@"
