# Plantilla de repo de código — Sistema Maestro

Seed de la **capa sistema** para arrancar un proyecto de código con agentes: seguridad determinista + archivos de ley + estructura de specs y docs. La capa *código* (lenguaje, framework, `src/`, CI) se completa en el kickoff de cada proyecto — deliberadamente no viene en la plantilla.

Origen: `SOP Proyectos de Código` (SOP-013) del [Sistema Maestro](https://github.com/aguilarL3/sistema-maestro-template), validado contra la industria (Anthropic best practices, AGENTS.md/Linux Foundation, github/spec-kit, Harper Reed). Todo en **español**.

**Requisitos:** [Git](https://git-scm.com) (con Git Bash en Windows) y Python — los usan los hooks de seguridad. Un agente de código (ej. [Claude Code](https://claude.ai/download)) para sacarle el jugo.

> **¿No usás el Sistema Maestro?** La plantilla funciona igual: el repo es autosuficiente por diseño. Escribí tu PRD directo en `docs/product/` y salteá los pasos marcados *(vault)* del kickoff — el resto aplica tal cual.

## Cómo se ve trabajar acá (con agente)

- Las **guardas corren solas**: `security-guard` bloquea comandos peligrosos *antes* de ejecutarse, y `secret-scan` frena cualquier commit con un secreto staged.
- Al cerrar una sesión que editó archivos, el **Stop hook exige el handoff** en `docs/BITACORA.md` — el próximo agente (aunque sea otro: Codex, Gemini CLI…) arranca con contexto, sin que le repitas nada.
- Los **commits son deliberados y con tests en verde** — acá no existe el auto-commit.

## Cómo usar la plantilla (kickoff, ~30-45 min)

Prerrequisito: PRD/MVP ya escrito en el vault dueño (personal o de empresa) — o donde pienses tu producto. Si no existe, primero eso: el repo no piensa el producto.

1. **Copiar esta carpeta** al nuevo proyecto: `cp -r plantilla-repo-codigo ~/dev/<proyecto>` y borrar el `.git/` copiado (`rm -rf .git`) — o usarla como GitHub template repo cuando se publique.
2. `cd ~/dev/<proyecto>` → **`bash setup.sh`** — hace `git init` si falta, activa el gate pre-commit (`core.hooksPath`) y chequea requisitos (Git Bash + Python). **Sin este paso el secret-scan NO corre**: la config de hooks es local y no viaja con el repo.
3. *(vault)* **Exportar el pack de contexto** del vault → `docs/product/PRD.md` (+ decisiones), con encabezado de fecha y origen. Push consciente: el repo nunca lee el vault por su cuenta. Sin vault: escribí el PRD directo ahí.
4. **Completar `AGENTS.md`**: nombre, qué es, stack y comandos reales. Borrar todo placeholder que no aplique — la ley se mantiene magra.
5. **Completar `README.proyecto.md` y renombrarlo a `README.md`** (pisa este archivo: la plantilla ya cumplió su función).
6. **Elegir stack e inicializar** (`npm create`, `uv init`, etc.). Configurar test runner y lint, y **cablearlos en `.githooks/pre-commit`** (hoy solo corre secret-scan). Tras unas sesiones, generar la allowlist de permisos del stack con `/fewer-permission-prompts` (del proyecto → `settings.json`; personal → `settings.local.json`).
7. **Primera spec**: `specs/001-mvp/spec.md` (qué) → `plan.md` (cómo) → `tasks.md` (pasos chicos, sin saltos de complejidad).
8. *(vault)* Crear la **nota de proyecto en el vault** (o actualizarla): campo `repo:` apuntando acá.
9. Abrir Claude Code **desde esta carpeta** (nunca desde el vault) y a construir.

> **Config local del operador** (`.claude/settings.local.json`, gitignoreado): allowlist personal y, si sos el dueño del vault, `additionalDirectories` hacia el vault de la **misma esfera** para consultas ad-hoc. Es un atajo de tu máquina, nunca una dependencia: el repo funciona completo sin el vault.

## Qué trae

| Pieza | Qué hace |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | Ley del repo (estándar AGENTS.md; CLAUDE.md la importa) |
| `.claude/settings.json` + `.claude/hooks/` | Baseline de Seguridad: deny + security-guard (PreToolUse) |
| `.githooks/pre-commit` | Gate de commit: secret-scan (agregar lint/tests en el paso 5) |
| `.gitignore` + `.env.example` | Secretos fuera del repo desde el día 1 |
| `docs/product/` | Destino del export pack del vault |
| `docs/adr/` | Decisiones técnicas (formato en su README) |
| `docs/BITACORA.md` + hooks `session-touch`/`agent-diary` | Handoffs entre sesiones de agente — el Stop hook pide la entrada solo en sesiones que editaron archivos (determinista, no advisory) |
| `setup.sh` | Activación por clon: hooksPath + renormalizar LF + chequeo de requisitos |
| `.gitattributes` | Hooks bash siempre LF (con CRLF se rompen en Git Bash/Windows) |
| `README.proyecto.md` | Esqueleto del README real del proyecto (paso 5 del kickoff) |
| `specs/000-ejemplo/` | Esqueleto spec → plan → tasks (borrar al crear la 001 real) |

## Reglas de la frontera (resumen del SOP-013)

- El **vault** piensa el producto (PRD, decisiones, investigación). El **repo** lo construye.
- El repo es **autosuficiente**: si no funciona sin el vault montado, la frontera está rota.
- Cambio de producto → se decide en el vault → se re-exporta el snapshot. Cambio técnico → `docs/adr/` acá.
- Al cerrar hitos: evidencia → Career OS del vault personal; patrón aprendido → `04 Knowledge/Temas/`.

## Licencia

[MIT](LICENSE) © 2026 Leandro Aguilar.
