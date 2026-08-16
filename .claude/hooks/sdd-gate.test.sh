#!/usr/bin/env bash
# Banco de pruebas del gate SDD.  ·  Correr: bash .claude/hooks/sdd-gate.test.sh
#
# Por qué este hook sí tiene tests y los otros no: sdd-gate es el único con
# lógica de máquina de estados (5 estados × 4 reglas, y varias combinaciones
# donde lo correcto es NO bloquear). Ahí un refactor rompe algo en silencio, y
# el modo de falla es el peor posible: un gate que deja pasar lo que debía
# frenar no avisa nunca. secret-scan y security-guard son patrones sobre texto;
# este es una máquina de estados.
#
# Cada caso levanta un repo git REAL en un temporal, stagea archivos y compara
# el exit code. No toca el repo donde vive. Requiere python (igual que el hook).
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
SRC="$ROOT/.claude/hooks"
PY="$(command -v python 2>/dev/null || command -v python3 2>/dev/null || true)"
if [ -z "$PY" ]; then echo "sin python: el gate no corre y este banco tampoco"; exit 0; fi

TMP="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

reset_repo() {
  rm -rf "$TMP/r"; mkdir -p "$TMP/r/.claude/hooks" "$TMP/r/specs" "$TMP/r/src"
  cp "$SRC/sdd-gate.sh" "$SRC/sdd-gate.py" "$TMP/r/.claude/hooks/"
  cd "$TMP/r" || exit 1
  git init -q -b main . >/dev/null 2>&1
  git config user.email t@t.t; git config user.name t
}

manifest() { # $1 = json de features, $2 = json de rules (opcional)
  rules="${2:-}"
  [ -z "$rules" ] && rules='{}'
  cat > feature_list.json <<EOF
{ "project": "test",
  "rules": $rules,
  "features": $1 }
EOF
  # Guarda del propio banco: con un JSON inválido el gate hace fail-open y los
  # casos "pasarían" por el motivo equivocado. Pasó de verdad al escribirlo.
  "$PY" -c "import json; json.load(open('feature_list.json'))" 2>/dev/null \
    || { echo "  ⛔ BANCO ROTO: feature_list.json inválido"; cat feature_list.json; exit 1; }
}

spec_dir() { # $1 = nombre, $2 = contenido de tasks.md
  mkdir -p "specs/$1"
  printf '%s\n' "${2:-- [x] T1: hecho}" > "specs/$1/tasks.md"
}

check() { # $1 = nombre del caso, $2 = exit esperado
  bash .claude/hooks/sdd-gate.sh >"$TMP/out" 2>&1
  got=$?
  if [ "$got" = "$2" ]; then
    PASS=$((PASS+1)); printf '  ✅ %s (exit %s)\n' "$1" "$got"
  else
    FAIL=$((FAIL+1)); printf '  ❌ %s → esperaba %s, dio %s\n' "$1" "$2" "$got"
    sed 's/^/       | /' "$TMP/out" | head -12
  fi
}

echo "== Gate SDD — banco de pruebas =="

# ── Inerte: el gate no debe existir para quien no usa SDD ────────────────────
reset_repo
echo "x" > src/app.js; git add -A 2>/dev/null
check "sin feature_list.json → inerte" 0

reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":false,"status":"spec_ready"}]'
spec_dir "001-pagos"
echo "x" > src/app.js; git add -A 2>/dev/null
check "sdd:false → inerte" 0

reset_repo
manifest '[{"id":0,"name":"000-ejemplo","sdd":true,"status":"pending"}]'
spec_dir "000-ejemplo"
echo "x" > src/app.js; git add -A 2>/dev/null
check "feature en pending + código → pasa" 0

# ── La puerta de aprobación ──────────────────────────────────────────────────
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]'
spec_dir "001-pagos"
echo "x" > src/app.js; git add -A 2>/dev/null
check "spec_ready + código → BLOQUEA" 1

reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]'
spec_dir "001-pagos"
mkdir -p docs; echo "x" > docs/nota.md; echo "y" > README.md; git add -A 2>/dev/null
check "spec_ready + solo docs → pasa" 0

# Falso positivo a evitar: con algo en curso, el código tiene dueño legítimo.
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"},
           {"id":2,"name":"002-login","sdd":true,"status":"in_progress"}]'
spec_dir "001-pagos"; spec_dir "002-login"
echo "x" > src/app.js; git add -A 2>/dev/null
check "spec_ready + otra in_progress + código → pasa" 0

# Agnóstico de stack: si esto pasara, un repo Python o Go quedaría sin gate.
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]'
spec_dir "001-pagos"
mkdir -p app; echo "x" > app/main.py; git add -A 2>/dev/null
check "spec_ready + app/main.py (no src/) → BLOQUEA" 1

# ── Auto-aprobación: el agente no puede aprobarse a sí mismo ─────────────────
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]'
spec_dir "001-pagos"; echo base > README.md
git add -A 2>/dev/null; git commit -qm base --no-verify >/dev/null 2>&1
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"in_progress"}]'
echo "x" > src/app.js; git add -A 2>/dev/null
check "auto-aprobación (aprueba + código juntos) → BLOQUEA" 1

reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]'
spec_dir "001-pagos"; echo base > README.md
git add -A 2>/dev/null; git commit -qm base --no-verify >/dev/null 2>&1
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"in_progress"}]'
git add -A 2>/dev/null
check "aprobación sola, sin código → pasa" 0

# Falso positivo a evitar: el flujo normal, ya aprobado en un commit anterior.
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"in_progress"}]'
spec_dir "001-pagos"; echo base > README.md
git add -A 2>/dev/null; git commit -qm "aprueba: 001-pagos" --no-verify >/dev/null 2>&1
echo "x" > src/app.js; git add -A 2>/dev/null
check "ya aprobada en commit previo + código → pasa" 0

reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"in_progress"}]'
spec_dir "001-pagos"
echo "x" > src/app.js; git add -A 2>/dev/null
check "sin HEAD previo → pasa sin reventar" 0

# ── Las otras reglas del manifiesto ──────────────────────────────────────────
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"in_progress"},
           {"id":2,"name":"002-login","sdd":true,"status":"in_progress"}]'
spec_dir "001-pagos"; spec_dir "002-login"
echo "x" > src/app.js; git add -A 2>/dev/null
check "dos in_progress → BLOQUEA" 1

reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"done"}]'
spec_dir "001-pagos" "- [ ] T2: falta esto"
git add -A 2>/dev/null
check "done con tasks abiertas (manifiesto staged) → BLOQUEA" 1

# Sin esta condición, una casilla vieja sin marcar bloquearía para siempre.
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"done"}]'
spec_dir "001-pagos" "- [ ] T2: falta esto"
git add -A 2>/dev/null; git commit -qm base --no-verify >/dev/null 2>&1
echo "x" > src/app.js; git add src/app.js 2>/dev/null
check "done con tasks abiertas (manifiesto no staged) → pasa" 0

reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"in_progress"}]'
echo "x" > src/app.js; git add -A 2>/dev/null
check "in_progress sin specs/ + código → BLOQUEA" 1

# ── Manda el manifiesto, no el hook ──────────────────────────────────────────
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]' \
         '{"require_approved_spec_to_implement": false}'
spec_dir "001-pagos"
echo "x" > src/app.js; git add -A 2>/dev/null
check "regla en false → no se aplica" 0

# ── Salidas de emergencia y fail-open ────────────────────────────────────────
reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]'
spec_dir "001-pagos"; mkdir -p .repo-meta; touch .repo-meta/sdd-gate.disabled
echo "x" > src/app.js; git add -A 2>/dev/null
check "kill-switch → pasa" 0

reset_repo
echo '{ roto' > feature_list.json
echo "x" > src/app.js; git add -A 2>/dev/null
check "manifiesto ilegible → fail-open" 0

reset_repo
manifest '[{"id":1,"name":"001-pagos","sdd":true,"status":"spec_ready"}]'
spec_dir "001-pagos"
check "nada staged → pasa" 0

echo ""
echo "== $PASS pasaron, $FAIL fallaron =="
[ "$FAIL" = 0 ]
