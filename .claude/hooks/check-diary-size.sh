#!/usr/bin/env bash
# check-diary-size.sh — tope de consolidación de docs/BITACORA.md.
#
# EL PROBLEMA: la bitácora está acotada al LEER (un agente que entra mira las
# últimas entradas) pero es infinita al ESCRIBIR. Y acá es **peor que en el vault
# del sistema**, por dos motivos propios de un repo de código:
#
#   1. NO ROTA. El vault corta por mes (`YYYY-MM.md`); esto es UN archivo único
#      que acumula toda la vida del proyecto. No hay ningún corte natural.
#   2. `merge=union`. Varios agentes en worktrees y varias personas en ramas
#      escriben en paralelo y sus entradas se INTERCALAN al mergear. El archivo
#      no crece por una sola vía, crece por todas a la vez.
#
# LA IDEA: lo valioso no es el número, es **el mecanismo que obliga a sintetizar**.
# A un agente al que solo se le pide "resumí bien" no lo hace; a uno que choca
# contra un tope, sí.
#
# NO BLOQUEA Y NO BORRA: hace que el hook `Stop` le pida al agente que PROPONGA la
# consolidación. La tijera la decide una persona. En un repo de código el destino
# natural de lo que sí hay que conservar es `docs/adr/` — una decisión técnica cara
# de revertir no es una entrada de diario, es un ADR.
#
# Mide CARACTERES, no líneas: las entradas son párrafos largos, y contar líneas
# subestimaría varias veces el costo real de leerla.
#
# USO:
#   bash .claude/hooks/check-diary-size.sh          → reporta el estado
#   bash .claude/hooks/check-diary-size.sh --level  → OK|SOFT|HARD (lo usa agent-diary.sh)
#
# Kill-switch: .repo-meta/diary-cap.disabled
# FAIL-OPEN: cualquier problema → exit 0 / nivel OK.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || { [ "${1:-}" = "--level" ] && echo "OK"; exit 0; }

FILE="docs/BITACORA.md"

# Umbrales más bajos que los del vault, justamente porque acá el archivo no rota:
# lo que allá es "un mes de trabajo" acá es "todo el proyecto hasta hoy".
SOFT_CHARS="${DIARY_SOFT_CHARS:-60000}"
HARD_CHARS="${DIARY_HARD_CHARS:-120000}"
SOFT_ENTRIES="${DIARY_SOFT_ENTRIES:-25}"
HARD_ENTRIES="${DIARY_HARD_ENTRIES:-50}"

if [ -f .repo-meta/diary-cap.disabled ] || [ ! -f "$FILE" ]; then
  [ "${1:-}" = "--level" ] && echo "OK"
  exit 0
fi

CHARS="$(wc -c < "$FILE" 2>/dev/null | tr -d ' ')"; CHARS="${CHARS:-0}"
ENTRIES="$(grep -cE '^#{2,3} 20[0-9][0-9]-[0-9]' "$FILE" 2>/dev/null || echo 0)"; ENTRIES="${ENTRIES:-0}"

if [ "$CHARS" -gt "$HARD_CHARS" ] || [ "$ENTRIES" -gt "$HARD_ENTRIES" ]; then
  LEVEL="HARD"
elif [ "$CHARS" -gt "$SOFT_CHARS" ] || [ "$ENTRIES" -gt "$SOFT_ENTRIES" ]; then
  LEVEL="SOFT"
else
  LEVEL="OK"
fi

if [ "${1:-}" = "--level" ]; then
  echo "$LEVEL"
  exit 0
fi

case "$LEVEL" in
  HARD) icon="🔴" ;;
  SOFT) icon="🟡" ;;
  *)    icon="✅" ;;
esac
echo "Tope de la bitácora (soft: ${SOFT_CHARS} chars / ${SOFT_ENTRIES} entradas · hard: ${HARD_CHARS} / ${HARD_ENTRIES})"
echo "  ${icon} ${FILE}: ${CHARS} chars · ${ENTRIES} entradas · ${LEVEL}"

if [ "$LEVEL" != "OK" ]; then
  echo
  echo "Qué significa consolidar acá (y qué NO):"
  echo "  · NO es borrar. La historia completa ya vive en git (\`git log -p -- $FILE\`)."
  echo "  · SÍ es: sintetizar las entradas viejas en aprendizajes duraderos, dejar"
  echo "    VERBATIM las últimas (que son el handoff vivo), y mandar a \`docs/adr/\` lo"
  echo "    que resultó ser una DECISIÓN técnica y no una nota de diario."
  echo "  · La propone un agente; la tijera final la decide una persona."
  echo
  echo "  Ojo con \`merge=union\`: consolidá desde la rama principal y con el árbol"
  echo "  limpio. Reescribir este archivo en una rama larga garantiza conflicto."
fi
exit 0
