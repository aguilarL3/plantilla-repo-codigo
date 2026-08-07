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

1. **Obtener el seed** por cualquiera de las dos vías (ninguna deja `origin` apuntando al template):
   - **"Use this template"** en GitHub → crea tu repo (marcalo privado si corresponde) → clonalo. *(Ya publicado como template repo.)*
   - O **copiar la carpeta** y arrancar git de cero: `cp -r plantilla-repo-codigo ~/dev/<proyecto>` y borrar el `.git/` copiado (`rm -rf .git`) — `setup.sh` hace `git init` fresco.
2. `cd ~/dev/<proyecto>` → **`bash setup.sh`** — hace `git init` si falta, activa el gate pre-commit (`core.hooksPath`) y chequea requisitos (Git Bash + Python). **Sin este paso el secret-scan NO corre**: la config de hooks es local y no viaja con el repo.
3. *(vault)* **Exportar el pack de contexto** del vault → `docs/product/PRD.md` (+ decisiones), con encabezado de fecha y origen. Push consciente: el repo nunca lee el vault por su cuenta. Sin vault: escribí el PRD directo ahí.
4. **Completar `AGENTS.md`**: nombre, qué es, stack y comandos reales. Borrar todo placeholder que no aplique — la ley se mantiene magra.
5. **Completar `README.proyecto.md` y renombrarlo a `README.md`** (pisa este archivo: la plantilla ya cumplió su función).
6. **Elegir stack e inicializar** (`npm create`, `uv init`, etc.). Configurar test runner y lint, y **cablearlos en los dos lugares**: `.githooks/pre-commit` (tu máquina) y `.github/workflows/verify.yml` (el PR) — los dos traen el bloque marcado. Hoy solo corre secret-scan. Tras unas sesiones, generar la allowlist de permisos del stack con `/fewer-permission-prompts` (del proyecto → `settings.json`; personal → `settings.local.json`).
7. **Primera spec**: `specs/001-mvp/spec.md` (qué) → `plan.md` (cómo) → `tasks.md` (pasos chicos, sin saltos de complejidad).
8. *(vault)* Crear la **nota de proyecto en el vault** (o actualizarla): campo `repo:` apuntando acá.
9. **Si van a ser más de uno:** ver *Más de una persona en el repo*, más abajo (son 4 pasos y uno es en GitHub).
10. Abrir Claude Code **desde esta carpeta** (nunca desde el vault) y a construir.

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
| `repo.conf` | `REPO_MODE=solo\|equipo` — el modo del repo (versionado, compartido) |
| `.github/workflows/verify.yml` | El gate del lado del servidor: secret-scan en cada PR |
| `.github/CODEOWNERS.example` | Quién **revisa** qué — copiar a `CODEOWNERS` para activar (no restringe quién escribe) |
| `COMO-TRABAJAMOS.example.md` | El acuerdo de trabajo en lenguaje llano — completar y renombrar cuando entra la segunda persona |

## Más de una persona en el repo

Un repo de un solo dueño no paga nada por esta capa: `REPO_MODE=solo` es el default y queda inerte. Cuando entra la segunda persona:

1. **`REPO_MODE=equipo` en `repo.conf`.** Desde ese commit el `pre-commit` bloquea commits directos a `main`: todo entra por PR.
2. **Completar `COMO-TRABAJAMOS.example.md` y renombrarlo a `COMO-TRABAJAMOS.md`**, linkeado desde el README del proyecto. Es lo que la persona nueva lee en diez minutos antes de su primer commit: prefijos de rama, zonas, secretos, qué hacer si algo sale mal. Si el repo está en plan Free, **este documento no acompaña al control: es el control**.
3. **`cp .github/CODEOWNERS.example .github/CODEOWNERS`** y poner los @usuarios reales — si va a servir de algo (ver el aviso de abajo).
4. **Cada persona corre `bash setup.sh` en su clon.** Es lo que activa `core.hooksPath`, y **el script aborta si no queda**.
5. **Reglas de rama en GitHub** (Settings → Rules, sobre `main`): require PR · require review from Code Owners · require status check `verify` · block force pushes. **Este paso no se puede automatizar desde el repo.**

> [!WARNING]
> **El paso 5 no existe en plan Free con repo privado.** La API responde `403 · "Upgrade to GitHub Pro or make this repository public"` tanto para *branch protection* como para *rulesets*. No es un permiso mal puesto: la función no está en el plan. Verificado 2026-08-06.
>
> Lo que eso cambia, y conviene aceptarlo explícitamente en vez de descubrirlo:
>
> | Pieza | En Free + privado |
> |---|---|
> | Rama por persona + PR + squash | ✅ funciona (es convención) |
> | `verify.yml` en el PR | ✅ corre — pero es **señal, no bloqueo**: un PR en rojo se mergea igual |
> | Require PR / review from Code Owners / status checks / block force pushes | ❌ no disponibles |
> | Gate de rama del `pre-commit` | ✅ **el único control automático real** |
>
> **`CODEOWNERS` en ese escenario** no restringe nada y ni siquiera auto-asigna revisor: queda como mapa documentado. Es una decisión razonable **diferirlo** y dejar las zonas en `COMO-TRABAJAMOS.md`, para no tener dos fuentes de verdad de lo mismo — una de ellas inerte. Si conviven y se contradicen, que esté escrito cuál manda.
>
> **Las tres salidas:** pasar a plan de pago, hacer el repo público, o aceptar la convención a conciencia. La tercera es legítima con dos personas que se hablan; con más deja de serlo.

> Por qué el gate de servidor importa: `core.hooksPath` es **config local**, no viaja con el repo, y `--no-verify` lo saltea en un teclazo. Con una persona eso es disciplina; con varias es estadística. Cuando el servidor no puede ayudar, **el paso 4 pasa de higiene a paso crítico** — verificalo (`git config core.hooksPath` → `.githooks`), no lo des por hecho.

## Varios agentes en paralelo

Un worktree por agente (`git worktree add -b agent/<nombre> ../<proyecto>-<nombre>`): cada uno tiene su checkout y su `.repo-meta/`, así que las marcas de sesión no se pisan. `docs/BITACORA.md` está marcado `merge=union` para que dos handoffs simultáneos se unan en vez de dar conflicto — y por eso cada entrada lleva **agente y rama** en el encabezado. Las reglas completas están en `AGENTS.md` §*Git: ramas, worktrees y trabajo en paralelo*, que es lo que leen los agentes.

## Reglas de la frontera (resumen del SOP-013)

- El **vault** piensa el producto (PRD, decisiones, investigación). El **repo** lo construye.
- El repo es **autosuficiente**: si no funciona sin el vault montado, la frontera está rota.
- Cambio de producto → se decide en el vault → se re-exporta el snapshot. Cambio técnico → `docs/adr/` acá.
- Al cerrar un hito, desde el vault personal (push consciente) y con `docs/BITACORA.md` como materia prima: **historia STAR** → Career OS (la R es dato de negocio, no está en la bitácora); **patrón aprendido** → `04 Knowledge/Temas/` (casi siempre Explanation). El código se queda acá.

## Licencia

[MIT](LICENSE) © 2026 Leandro Aguilar.
