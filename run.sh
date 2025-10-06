#!/usr/bin/bash
# ==========================================
# Aksan Smart Shell v8 - Portable Launcher
# ==========================================
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
export ASS_BASE="$BASE_DIR"
export ASS_LIB="$BASE_DIR/lib"
export ASS_CONF="$BASE_DIR/config"
export ASS_DATA="$BASE_DIR/data"
mkdir -p "$ASS_DATA"
bash "$ASS_BASE/bin/ass" "$@"
