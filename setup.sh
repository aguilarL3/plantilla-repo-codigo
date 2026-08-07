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
# Se VERIFICA leyendo de vuelta, no se asume: sin reglas de rama en el servidor
# (ver el bloque de modo equipo) este es el único control que existe, y un setup
# que dice "[ok]" sin comprobarlo es exactamente el modo de falla que importa.
git config core.hooksPath .githooks
HOOKS_PATH="$(git config core.hooksPath 2>/dev/null || true)"
if [ "$HOOKS_PATH" = ".githooks" ]; then
  echo "[ok] core.hooksPath = .githooks (gate activo en cada commit)"
else
  echo "[ERROR] core.hooksPath quedó en «${HOOKS_PATH:-<vacío>}», no en .githooks."
  echo "        SIN ESTO NO TENÉS NINGÚN GATE: ni secret-scan, ni gate de rama, ni tests."
  echo "        No sigas: revisá permisos de .git/config y volvé a correr este script."
  exit 1
fi

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
    echo "[i] no hay .github/CODEOWNERS (solo el .example). Sirve para AUTO-ASIGNAR"
    echo "    revisor en el PR; NO restringe quién escribe, y sin «Require review"
    echo "    from Code Owners» (plan de pago, ver abajo) tampoco obliga a nada."
    echo "    Si en este repo está diferido a propósito, las zonas viven en el"
    echo "    acuerdo escrito — ese es el documento vigente, no este archivo."
  fi

  # Identidad de commit: en equipo el autor tiene que ser la persona, no un default.
  if [ -z "$(git config user.email 2>/dev/null)" ]; then
    echo "[AVISO] no tenés user.email configurado — tus commits van a quedar sin autor identificable."
    echo "        git config user.name \"Tu Nombre\" && git config user.email \"vos@ejemplo.com\""
  fi

  # El acuerdo en lenguaje llano. En plan Free ESTE documento es el control real,
  # así que si existe hay que leerlo — no es material de referencia opcional.
  if [ -f COMO-TRABAJAMOS.md ]; then
    echo "[!] LEÉ ./COMO-TRABAJAMOS.md antes de tu primer commit (10 min)."
  fi

  echo ""
  echo "   ⚠️ Reglas de rama del lado del servidor — NO se activan desde el repo:"
  echo "      GitHub → Settings → Rules → sobre «$MAIN_BRANCH»"
  echo "        · Require a pull request before merging"
  echo "        · Require review from Code Owners"
  echo "        · Require status checks to pass → check «verify»"
  echo "        · Block force pushes"
  echo ""
  echo "   🔴 OJO: en plan FREE con repo PRIVADO esas reglas NO EXISTEN."
  echo "      La API responde 403 «Upgrade to GitHub Pro or make this repository"
  echo "      public». No es un permiso mal puesto: la función no está en el plan."
  echo "      Si es tu caso, leé la lista de arriba como «lo que tendrías si"
  echo "      pagaras», no como un pendiente que podés resolver hoy."
  echo ""
  echo "   → Consecuencia: el pre-commit de ESTA máquina es el único control real."
  echo "     Se saltea con --no-verify, así que el resto es acuerdo entre personas."
fi

echo ""
echo "== Listo. Siguiente: completar AGENTS.md y exportar el PRD a docs/product/ (ver README) =="
