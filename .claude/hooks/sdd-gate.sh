#!/usr/bin/env bash
# sdd-gate.sh — gate pre-commit del flujo Spec-Driven Development.
#
# Wrapper delgado (mismo patrón que security-guard.sh): kill-switch, ubicar
# python y delegar la lógica en sdd-gate.py, que parsea feature_list.json.
#
# Qué frena: escribir código de una feature cuyo spec el humano no aprobó
# todavía. Hasta ahora esa puerta vivía solo como instrucción en AGENTS.md,
# mientras el resto del repo se apoya en gates deterministas.
#
# Lo invoca .githooks/pre-commit. Exit != 0 => aborta el commit.
# FAIL-OPEN sin python o sin manifiesto; FAIL-CLOSED ante violación.
# Kill-switch: .repo-meta/sdd-gate.disabled  ·  CLI: bash .claude/hooks/sdd-gate.sh
#
# Acepta --range <BASE> [HEAD] para CI (en un PR no hay nada staged), igual
# que secret-scan.sh. Ver .github/workflows/verify.yml
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
cd "$ROOT" 2>/dev/null || exit 0
[ -f .repo-meta/sdd-gate.disabled ] && exit 0
[ -f feature_list.json ] || exit 0   # repo sin SDD -> inerte

PY="$(command -v python 2>/dev/null || command -v python3 2>/dev/null || true)"
if [ -z "$PY" ]; then
  # Mismo criterio que security-guard: sin python no se bloquea trabajo. Pero
  # acá se avisa, porque a diferencia de aquel no queda ninguna capa detrás.
  echo "[i] sdd-gate: falta python — el gate SDD no corre (secret-scan sigue activo)." >&2
  exit 0
fi

exec "$PY" "$ROOT/.claude/hooks/sdd-gate.py" "$@"
