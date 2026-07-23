#!/usr/bin/env bash
# Setup del repo (correr UNA vez por clon/copia — Git Bash en Windows).
# Activa el gate pre-commit y verifica los requisitos del baseline de seguridad.
# Sin esto, el secret-scan NO corre: core.hooksPath es config local y no viaja con el repo.
#
# Lo corren los DOS caminos: quien crea el repo desde la plantilla, y cada
# persona que después lo clona. No es un paso de fundador.
set -uo pipefail
cd "$(dirname "$0")"

echo "== Setup plantilla-repo-codigo =="

# 0. Modo del repo (compartido, versionado en repo.conf)
# Se PARSEA, no se sourcea: repo.conf es un archivo versionado, y sourcearlo
# haría que un PR a la config ejecute shell en la máquina de quien clona.
conf_get() {
  val="$(sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([A-Za-z0-9._/-]*\).*/\1/p" repo.conf 2>/dev/null | head -1)"
  if [ -n "$val" ]; then printf '%s' "$val"; else printf '%s' "$2"; fi
}
REPO_MODE="$(conf_get REPO_MODE solo)"
MAIN_BRANCH="$(conf_get MAIN_BRANCH main)"
echo "[i] REPO_MODE = $REPO_MODE (cambiar en repo.conf)"

# 1. Repo git (si la carpeta se copió sin .git)
if [ ! -d .git ]; then
  git init -b "$MAIN_BRANCH"
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

# 5. Modo equipo: lo que el gate local NO puede garantizar por sí solo
if [ "$REPO_MODE" = "equipo" ]; then
  echo ""
  echo "== Modo equipo =="
  echo "[ok] pre-commit bloquea commits directos a «$MAIN_BRANCH» (todo entra por PR)"

  if [ -f .github/CODEOWNERS ]; then
    echo "[ok] .github/CODEOWNERS presente"
  else
    echo "[AVISO] falta .github/CODEOWNERS — copialo de .github/CODEOWNERS.example y poné los @usuarios."
    echo "        Sin él, un PR puede tocar AGENTS.md, .claude/ o los hooks sin revisión del dueño."
  fi

  # Identidad de commit: en equipo el autor tiene que ser la persona, no un default.
  if [ -z "$(git config user.email 2>/dev/null)" ]; then
    echo "[AVISO] no tenés user.email configurado — tus commits van a quedar sin autor identificable."
    echo "        git config user.name \"Tu Nombre\" && git config user.email \"vos@ejemplo.com\""
  fi

  echo ""
  echo "   ⚠️ Esto NO se puede activar desde el repo — va en GitHub"
  echo "      (Settings → Rules → sobre «$MAIN_BRANCH»):"
  echo "        · Require a pull request before merging"
  echo "        · Require review from Code Owners"
  echo "        · Require status checks to pass → check «verify»"
  echo "        · Block force pushes"
  echo "      Sin esas reglas, lo de arriba es una convención que se saltea con --no-verify."
fi

echo ""
echo "== Listo. Siguiente: completar AGENTS.md y exportar el PRD a docs/product/ (ver README) =="
