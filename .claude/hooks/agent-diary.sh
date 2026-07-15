#!/usr/bin/env bash
# Stop hook — Agent Diary (adaptación para repos de código del hook del vault Sistema Maestro).
# Si la sesión editó archivos, hace que el agente registre su handoff en docs/BITACORA.md
# ANTES de terminar (contexto para la próxima sesión).
#
# Mecánica:
#   - Guard anti-loop: si el modelo ya reentró por el Stop (stop_hook_active=true),
#     limpia la marca y permite terminar.
#   - Dispara solo si existe .repo-meta/session-touched (la deja session-touch.sh en PostToolUse).
#   - Dedupe por sesión: bloquea UNA sola vez por session_id (stamp .repo-meta/diary-done-<sid>).
#     Si el agente sigue trabajando tras registrar, la convención es AMPLIAR su entrada.
#   - Kill-switch: .repo-meta/diary.disabled
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0

INPUT="$(cat)"

# Guard anti-loop: segunda pasada → limpiar marca y salir.
case "$INPUT" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*)
    rm -f .repo-meta/session-touched 2>/dev/null || true
    exit 0 ;;
esac

# Kill-switch.
[ -f .repo-meta/diary.disabled ] && exit 0

# ¿Hubo ediciones esta sesión?
[ -f .repo-meta/session-touched ] || exit 0

# Dedupe por sesión.
SID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$SID" ] || SID="dia-$(date +%Y-%m-%d)"
STAMP=".repo-meta/diary-done-${SID}"
[ -f "$STAMP" ] && exit 0
mkdir -p .repo-meta 2>/dev/null || true
: > "$STAMP" 2>/dev/null || true
find .repo-meta -maxdepth 1 -name 'diary-done-*' -mtime +7 -delete 2>/dev/null || true

DAY="$(date +%Y-%m-%d)"

printf '{"decision":"block","reason":"[AGENT DIARY] Esta sesión editó archivos del repo. Antes de terminar, registrá UNA entrada al FINAL de docs/BITACORA.md con este formato:\\n\\n## %s — <tu agente>\\n- Qué se avanzó: (con estado de tests: en verde / rotos / no corridos)\\n- Qué quedó bloqueado:\\n- Qué se decidió: (si es técnica cara de revertir → también a docs/adr/)\\n- Qué debe saber el próximo agente:\\n\\nREGLAS: la entrada más reciente SIEMPRE abajo. UNA entrada por sesión: si seguís trabajando después, AMPLIÁ la tuya (no crees otra). Después terminá normalmente. (Desactivar: crear .repo-meta/diary.disabled)"}' "$DAY"
exit 0
