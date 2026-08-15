#!/usr/bin/env python3
"""
sdd-gate.py — gate del flujo Spec-Driven Development.

Convierte en control determinista lo que hasta ahora era una instrucción en
markdown: que no se escriba código de una feature cuyo spec el humano todavía
no aprobó. El resto del repo se apoya en gates (secret-scan, gate de rama);
esta puerta era la única que dependía de que el agente obedeciera.

Le da ejecutor a las reglas que `feature_list.json` ya declaraba y nadie hacía
cumplir:
  · require_approved_spec_to_implement → no se toca código con la spec sin aprobar
  · one_feature_at_a_time              → no hay dos features en vuelo a la vez
  · require_tests_to_close             → no se cierra una feature con tasks abiertas

Si el repo pone una regla en `false`, el gate NO la aplica: el manifiesto manda.

Lo invoca .claude/hooks/sdd-gate.sh. Exit 1 => aborta el commit.
FAIL-OPEN ante error propio o repo sin SDD; FAIL-CLOSED ante violación.
Kill-switch: .repo-meta/sdd-gate.disabled

Dos modos (mismos chequeos), igual que secret-scan.sh:
  (por defecto)          → lo STAGED. Modo del hook pre-commit.
  --range <BASE> [HEAD]  → lo que cambió entre dos refs. Modo de CI: en un PR
                           no hay nada staged. Ver .github/workflows/verify.yml

Lee `feature_list.json` y los `tasks.md` del árbol de trabajo (no del index):
es lo que ven el humano y el agente cuando miran el repo.
"""
import json
import os
import subprocess
import sys

# Windows codifica stderr con la codepage local (cp1252), así que el emoji sale
# como «\U0001f534» y los acentos como «?». Los hooks en bash no tienen el
# problema porque escriben UTF-8 crudo; acá hay que pedirlo. Si la versión de
# Python no lo soporta, se sigue igual: un mensaje feo es mejor que un crash.
for _stream in (sys.stderr, sys.stdout):
    try:
        _stream.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass

MANIFEST = "feature_list.json"

# Qué NO cuenta como "tocar código". Todo lo que caiga fuera de esta lista sí.
# Allowlist en vez de una lista de extensiones de código: la plantilla es
# agnóstica de stack y no sabe si el proyecto usa src/, app/, lib/ o cmd/.
DOC_PREFIXES = ("specs/", "docs/", ".github/", ".claude/", ".githooks/", ".repo-meta/")
DOC_EXACT = {
    MANIFEST, "repo.conf", "setup.sh", "LICENSE",
    ".gitignore", ".gitattributes", ".env.example",
}


def run(args):
    """git a secas; devuelve stdout o '' si falla (nunca revienta el commit)."""
    try:
        out = subprocess.run(
            args, capture_output=True, text=True, encoding="utf-8", errors="replace"
        )
        return out.stdout if out.returncode == 0 else ""
    except Exception:
        return ""


def changed_files(range_base=None, range_head="HEAD"):
    # `-c core.quotepath=false`: sin esto git escapa las rutas no-ASCII
    # (`specs/Migraci\303\263n/…`) y dejan de matchear la allowlist.
    base = ["git", "-c", "core.quotepath=false", "diff", "--name-only"]
    args = base + ["%s...%s" % (range_base, range_head)] if range_base else base + ["--cached"]
    return [l.strip() for l in run(args).splitlines() if l.strip()]


def is_code(path):
    p = path.replace("\\", "/")
    if p in DOC_EXACT or p.startswith(DOC_PREFIXES):
        return False
    # Markdown suelto en la raíz (README, AGENTS, CLAUDE, COMO-TRABAJAMOS…).
    if "/" not in p and p.lower().endswith(".md"):
        return False
    return True


def previous_manifest(ref):
    """El manifiesto como estaba antes de este cambio. None si no se puede leer."""
    raw = run(["git", "show", "%s:%s" % (ref, MANIFEST)])
    if not raw:
        return None  # primer commit, o el manifiesto es nuevo
    try:
        return json.loads(raw)
    except ValueError:
        return None


def unchecked_tasks(feature_name):
    """Tareas `- [ ]` abiertas en specs/<feature>/tasks.md."""
    path = os.path.join("specs", feature_name, "tasks.md")
    if not os.path.isfile(path):
        return []
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            lines = fh.read().splitlines()
    except OSError:
        return []
    return [l.strip() for l in lines if l.strip().startswith(("- [ ]", "* [ ]"))]


def main():
    argv = sys.argv[1:]
    range_base = range_head = None
    if argv and argv[0] == "--range":
        range_base = argv[1] if len(argv) > 1 else ""
        range_head = argv[2] if len(argv) > 2 else "HEAD"
        if not range_base:
            print("sdd-gate: --range necesita <BASE> [HEAD]", file=sys.stderr)
            return 0

    if not os.path.isfile(MANIFEST):
        return 0  # repo sin SDD → inerte

    try:
        with open(MANIFEST, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        # Un manifiesto roto no bloquea: probablemente se esté arreglando en
        # este mismo commit. Avisar y salir.
        print("[i] sdd-gate: no pude leer %s (%s) — gate omitido." % (MANIFEST, exc), file=sys.stderr)
        return 0

    rules = data.get("rules") or {}
    features = [f for f in (data.get("features") or []) if f.get("sdd")]
    if not features:
        return 0  # ninguna feature bajo SDD → inerte

    changed = changed_files(range_base, range_head)
    if not changed:
        return 0
    code_touched = [p for p in changed if is_code(p)]
    manifest_touched = MANIFEST in [p.replace("\\", "/") for p in changed]

    def named(f):
        return f.get("name") or ("id %s" % f.get("id", "?"))

    spec_ready = [f for f in features if f.get("status") == "spec_ready"]
    in_progress = [f for f in features if f.get("status") == "in_progress"]
    done = [f for f in features if f.get("status") == "done"]

    problems = []  # (título, [líneas de detalle])

    # ── 1. La puerta de aprobación ───────────────────────────────────────────
    # Solo si NO hay nada en curso: con una feature en `in_progress` el código
    # que se toca tiene dueño legítimo, y bloquear sería un falso positivo.
    if rules.get("require_approved_spec_to_implement", True):
        if code_touched and spec_ready and not in_progress:
            problems.append((
                "Hay una spec esperando tu aprobación y este commit toca código.",
                ["· %s → estado «spec_ready»" % named(f) for f in spec_ready]
                + [
                    "",
                    "  Archivos de código en este commit:",
                ]
                + ["    %s" % p for p in code_touched[:8]]
                + (["    … y %d más" % (len(code_touched) - 8)] if len(code_touched) > 8 else [])
                + [
                    "",
                    "  Leé la spec y, si estás de acuerdo, pasala a «in_progress»",
                    "  en %s. Esa transición es TUYA: es el único" % MANIFEST,
                    "  punto donde decidís qué se construye antes de que se construya.",
                ],
            ))

    # ── 1b. Auto-aprobación ──────────────────────────────────────────────────
    # El gate lee un manifiesto que el propio agente puede escribir: mover
    # `spec_ready → in_progress` y meter el código en el mismo commit esquiva
    # el chequeo de arriba por completo. El hook no puede saber QUIÉN editó el
    # archivo, así que no distingue «el humano aprobó» de «el agente se aprobó
    # solo». Lo que sí puede exigir es que la aprobación sea su PROPIO commit:
    # así queda como un hecho fechado y auditable en el historial, en vez de
    # disolverse dentro del commit que ya trae el código.
    if rules.get("require_approved_spec_to_implement", True) and code_touched and in_progress:
        prev = previous_manifest(range_base or "HEAD")
        if prev is not None:
            antes = {}
            for f in prev.get("features") or []:
                antes[f.get("name") or f.get("id")] = f.get("status")
            recien = [f for f in in_progress
                      if antes.get(f.get("name") or f.get("id")) == "spec_ready"]
            if recien:
                nombres = ", ".join(named(f) for f in recien)
                problems.append((
                    "La aprobación de la spec y su implementación van en el mismo commit.",
                    ["· %s: spec_ready → in_progress, junto con el código" % nombres,
                     "",
                     "  Así el commit se aprueba a sí mismo y no queda registro de que",
                     "  alguien haya decidido nada. Separalos — la aprobación primero:",
                     "",
                     "    git commit %s -m \"aprueba: %s\"" % (MANIFEST, nombres),
                     "",
                     "  y después el código. La aprobación queda fechada en el historial.",
                     ],
                ))

    # ── 2. Una feature a la vez ──────────────────────────────────────────────
    if rules.get("one_feature_at_a_time", True) and len(in_progress) > 1:
        problems.append((
            "Hay %d features en «in_progress» a la vez." % len(in_progress),
            ["· %s" % named(f) for f in in_progress]
            + [
                "",
                "  El manifiesto declara one_feature_at_a_time. Cerrá o pasá a",
                "  «blocked» las que no estés construyendo ahora.",
            ],
        ))

    # ── 3. Feature en curso sin su spec ──────────────────────────────────────
    if code_touched:
        huerfanas = [f for f in in_progress if not os.path.isdir(os.path.join("specs", f.get("name") or ""))]
        if huerfanas:
            problems.append((
                "Una feature está «in_progress» pero no tiene carpeta de spec.",
                ["· %s → falta specs/%s/" % (named(f), f.get("name") or "?") for f in huerfanas]
                + [
                    "",
                    "  Estás escribiendo código contra una spec que no existe.",
                    "  Creá la trinidad (spec.md · plan.md · tasks.md) o corregí el nombre.",
                ],
            ))

    # ── 4. Cerrar con tareas abiertas ────────────────────────────────────────
    # Solo cuando el manifiesto entra en el commit: es cuando se está cerrando
    # algo. Chequearlo siempre convertiría una casilla vieja sin marcar en un
    # bloqueo permanente, y un gate que molesta sin motivo termina apagado.
    if rules.get("require_tests_to_close", True) and manifest_touched:
        for f in done:
            abiertas = unchecked_tasks(f.get("name") or "")
            if abiertas:
                problems.append((
                    "«%s» está marcada «done» con tareas sin cerrar." % named(f),
                    ["· %s" % t for t in abiertas[:5]]
                    + (["· … y %d más" % (len(abiertas) - 5)] if len(abiertas) > 5 else [])
                    + [
                        "",
                        "  En specs/%s/tasks.md. El manifiesto declara" % (f.get("name") or "?"),
                        "  require_tests_to_close: cada task cierra con su test en verde.",
                    ],
                ))

    if not problems:
        return 0

    # El encabezado y la salida de emergencia dependen del modo: en CI el commit
    # ya existe, así que hablar de «el commit no se hizo» y ofrecer --no-verify
    # sería mentir. Solo se nombra lo que aplica donde el mensaje se lee.
    out = sys.stderr
    if range_base:
        print("🔴 gate SDD: este cambio no respeta el flujo del manifiesto.", file=out)
    else:
        print("🔴 pre-commit (gate SDD): el commit no se hizo.", file=out)
    for titulo, detalle in problems:
        print("", file=out)
        print("   %s" % titulo, file=out)
        for linea in detalle:
            print(("   %s" % linea) if linea else "", file=out)
    print("", file=out)
    if range_base:
        print("   Se corrige en el repo (estado del manifiesto o alcance del cambio),", file=out)
        print("   no acá: este paso informa, no bloquea el PR.", file=out)
    else:
        print("   (Excepción puntual: git commit --no-verify.", file=out)
        print("    Kill-switch: .repo-meta/sdd-gate.disabled)", file=out)
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # fail-open: un bug acá no bloquea el trabajo
        print("[i] sdd-gate: error interno (%s) — gate omitido." % exc, file=sys.stderr)
        sys.exit(0)
