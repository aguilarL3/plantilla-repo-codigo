# CLAUDE.md — [NOMBRE DEL PROYECTO]

La ley de este repo vive en un solo lugar: @AGENTS.md

## Específico de Claude Code

- Cambios multi-archivo o de enfoque incierto: plan mode primero (Explore → Plan → Implement → Commit). Fixes de una línea: directo.
- Features con `"sdd": true`: entrevistame con AskUserQuestion hasta cubrir los casos difíciles → escribí la spec (`spec.md` con EARS `R1..Rn`, `plan.md`, `tasks.md` con `T1..Tn`) → cambiá el estado a `spec_ready` en `feature_list.json` y **pedí aprobación**.
- Tras la aprobación (la da el humano, no vos): despachá al subagente `@implementer` para construir las tareas en contexto fresco.
- Antes de commitear, **las dos cosas** — miran problemas distintos y ninguna cubre a la otra:
  - `@reviewer` → **¿cumple la spec?** Trazabilidad `R<n>` ↔ test, fuera de alcance, `AGENTS.md`.
  - `/code-review` → **¿tiene bugs?** Correctitud, en contexto fresco. Una feature puede satisfacer los cuatro requisitos EARS y tener un off-by-one.
- Para probar end-to-end antes de un commit importante: `/verify`.
- Investigaciones amplias del codebase: subagentes, para no llenar el contexto principal.
