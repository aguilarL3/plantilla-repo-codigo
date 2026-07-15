#!/usr/bin/env bash
# Setup del repo (correr UNA vez por clon/copia — Git Bash en Windows).
# Activa el gate pre-commit y verifica los requisitos del baseline de seguridad.
# Sin esto, el secret-scan NO corre: core.hooksPath es config local y no viaja con el repo.
set -uo pipefail
cd "$(dirname "$0")"

echo "== Setup plantilla-repo-codigo =="

# 1. Repo git (si la carpeta se copió sin .git)
if [ ! -d .git ]; then
  git init -b main
  echo "[ok] git init"
fi

# 2. Gate pre-commit (secret-scan; agregar lint/tests al elegir stack)
git config core.hooksPath .githooks
echo "[ok] core.hooksPath = .githooks (secret-scan activo en cada commit)"

# 3. Normalizar fin de línea de los hooks (crítico en Windows)
git add --renormalize . 2>/dev/null || true

# 4. Requisitos del security-guard
command -v bash >/dev/null || echo "[AVISO] falta bash (Git Bash en Windows)"
if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
  echo "[ok] python disponible (security-guard operativo)"
else
  echo "[AVISO] falta python: security-guard queda fail-open (los deny de settings.json siguen activos)"
fi

echo "== Listo. Siguiente: completar AGENTS.md y exportar el PRD a docs/product/ (ver README) =="
