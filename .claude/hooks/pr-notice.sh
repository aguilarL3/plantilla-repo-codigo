#!/usr/bin/env bash
# SessionStart: avisa si hay Pull Requests abiertos que esperan algo de vos.
#
# POR QUÉ EXISTE. En modo equipo el trabajo entra por PR, pero nada garantiza que
# te enteres: `CODEOWNERS` NO auto-asigna revisor en repos privados con plan Free
# (verificado 2026-08-07: PRs abiertos con el archivo ya correcto y las dos
# personas listadas quedaron con `requested_reviewers` vacío), así que la vista
# "te pidieron review" de GitHub y de `gh pr status` queda muerta. Sin esto, un PR
# de otra persona puede esperar días.
#
# Por eso NO se apoya en review requests: lista los PR ABIERTOS y separa los que
# no son tuyos. Es la única señal confiable en ese escenario.
#
# Fail-open SIEMPRE: sin `gh`, sin autenticación, sin python, sin red o con
# timeout → silencio y exit 0. Un hook de sesión no debe impedir abrir la sesión.
#
# Inerte fuera de modo equipo: con un solo dueño no hay PR de nadie más.
# Kill-switch: .repo-meta/pr-notice.disabled
ROOT="${CLAUDE_PROJECT_DIR:-.}"
cd "$ROOT" 2>/dev/null || exit 0
[ -f .repo-meta/pr-notice.disabled ] && exit 0

# Solo en modo equipo. repo.conf es config compartida y versionada: se PARSEA, no
# se sourcea — un `. ./repo.conf` convertiría un PR a la config en ejecución de
# código en la máquina de cada persona, en cada sesión.
conf_get() {
  val="$(sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([A-Za-z0-9._/-]*\).*/\1/p" repo.conf 2>/dev/null | head -1)"
  if [ -n "$val" ]; then printf '%s' "$val"; else printf '%s' "$2"; fi
}
[ "$(conf_get REPO_MODE solo)" = "equipo" ] || exit 0

command -v gh >/dev/null 2>&1 || exit 0
PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || exit 0

run() { if command -v timeout >/dev/null 2>&1; then timeout 8 "$@"; else "$@"; fi; }

# Tu usuario de GitHub, cacheado: es una llamada de red cuyo resultado no cambia.
LOGIN_CACHE=".repo-meta/gh-login"
ME="$(cat "$LOGIN_CACHE" 2>/dev/null | tr -d '[:space:]')"
if [ -z "$ME" ]; then
  ME="$(run gh api user --jq .login 2>/dev/null | tr -d '[:space:]')"
  [ -n "$ME" ] || exit 0
  mkdir -p .repo-meta 2>/dev/null || true
  printf '%s' "$ME" > "$LOGIN_CACHE" 2>/dev/null || true
fi

PRS="$(run gh pr list --state open --limit 20 \
        --json number,title,author,isDraft 2>/dev/null)"
[ -n "$PRS" ] && [ "$PRS" != "[]" ] || exit 0

printf '%s' "$PRS" | "$PY" -c '
import sys, json
try:
    prs = json.load(sys.stdin)
except Exception:
    sys.exit(0)
me = sys.argv[1] if len(sys.argv) > 1 else ""
vivos = [p for p in prs if not p.get("isDraft")]
def autor(p): return (p.get("author") or {}).get("login") or "?"
otros = [p for p in vivos if autor(p) != me]
mios  = [p for p in vivos if autor(p) == me]
if otros:
    print("[PR] %d esperan TU review:" % len(otros))
    for p in otros:
        print("  #%s  %s  (de %s)" % (p["number"], p["title"][:70], autor(p)))
    print("      Ver: gh pr view <n> --web    |    Diff: gh pr diff <n>")
if mios:
    print("[PR] %d tuyos, esperando review de la otra persona:" % len(mios))
    for p in mios:
        print("  #%s  %s" % (p["number"], p["title"][:70]))
' "$ME" 2>/dev/null

exit 0
