#!/usr/bin/env bash
# kloop — instala (ou sincroniza) os agents e commands no opencode.
# Requerido após qualquer alteração neste repo (instalação é por cópia).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_AGENTS="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/agents"
DEST_COMMANDS="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/commands"

mkdir -p "$DEST_AGENTS" "$DEST_COMMANDS"

cp "$SRC"/agents/kloop*.md "$DEST_AGENTS/"
cp "$SRC"/commands/kloop.md "$DEST_COMMANDS/"

echo "✓ kloop instalado:"
echo "  agents  → $DEST_AGENTS (kloop, kloop-architect, kloop-coder, kloop-reviewer, kloop-analyst, kloop-tester)"
echo "  command → $DEST_COMMANDS/kloop.md (/kloop)"
echo "Reinicie o opencode para as alterações terem efeito."
