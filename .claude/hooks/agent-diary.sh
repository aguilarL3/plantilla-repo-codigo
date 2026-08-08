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

# Rama actual: con varios agentes en worktrees (o varias personas en ramas), el
# orden del archivo deja de identificar quién escribió qué — la entrada tiene que
# decirlo. Se sanitiza porque el valor se interpola dentro de un string JSON.
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -cd 'A-Za-z0-9._/-' | head -c 60)"
[ -n "$BRANCH" ] || BRANCH="sin-rama"

# Tope de consolidación: docs/BITACORA.md no rota (a diferencia del vault, que
# corta por mes) y encima recibe entradas de varias ramas por merge=union, así que
# sin techo crece toda la vida del proyecto. Si se pasó, el aviso suma la
# instrucción de PROPONER una consolidación — este es el único momento en que el
# agente ya está con la bitácora en la mano.
# El fragmento va sin comillas dobles ni backslashes: se inyecta en un string JSON.
CAP_MSG=""
case "$(bash "$ROOT/.claude/hooks/check-diary-size.sh" --level 2>/dev/null || echo OK)" in
  SOFT) CAP_MSG='\n\nNOTA DE TAMAÑO: docs/BITACORA.md va larga. Sé breve y no repitas lo que ya está en entradas previas.' ;;
  HARD) CAP_MSG='\n\n⚠ TOPE DE CONSOLIDACIÓN ALCANZADO: docs/BITACORA.md superó el techo (corré «bash .claude/hooks/check-diary-size.sh» para ver los números). Además de tu entrada, PROPONÉ una consolidación: sintetizar las entradas viejas en aprendizajes duraderos, dejar VERBATIM las últimas, y mandar a docs/adr/ lo que sea una DECISIÓN técnica y no una nota de diario. NO consolides por tu cuenta: proponé y esperá aprobación. Y si lo hacés, hacelo desde la rama principal con el árbol limpio: este archivo es merge=union y reescribirlo en una rama larga garantiza conflicto.' ;;
esac

printf '{"decision":"block","reason":"[AGENT DIARY] Esta sesión editó archivos del repo. Antes de terminar, registrá UNA entrada al FINAL de docs/BITACORA.md con este formato:\\n\\n## %s — <tu agente> (rama: %s)\\n- Qué se avanzó: (con estado de tests: en verde / rotos / no corridos)\\n- Qué quedó bloqueado:\\n- Qué se decidió: (si es técnica cara de revertir → también a docs/adr/)\\n- Qué debe saber el próximo agente:\\n\\nREGLAS: la entrada más reciente SIEMPRE abajo. UNA entrada por sesión: si seguís trabajando después, AMPLIÁ la tuya (no crees otra). Poné SIEMPRE tu agente y tu rama en el encabezado: el archivo es merge=union, así que si otro agente trabajó en paralelo sus entradas se van a intercalar con las tuyas y el orden no alcanza para saber quién escribió qué. Después terminá normalmente. (Desactivar: crear .repo-meta/diary.disabled)%s"}' "$DAY" "$BRANCH" "$CAP_MSG"
exit 0
