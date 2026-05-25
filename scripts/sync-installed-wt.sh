#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_DIR
PREFIX="${WT_SYNC_PREFIX:-$HOME/.local/bin}"
readonly PREFIX

exec bash "$SCRIPT_DIR/install.sh" --shell none --prefix "$PREFIX"
