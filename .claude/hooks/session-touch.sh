#!/usr/bin/env bash
# PostToolUse (Edit|Write|NotebookEdit) — deja la marca "esta sesión editó archivos".
# La consume agent-diary.sh (Stop) para pedir bitácora solo en sesiones con trabajo real.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
mkdir -p "$ROOT/.repo-meta" 2>/dev/null || true
: > "$ROOT/.repo-meta/session-touched" 2>/dev/null || true
exit 0
