# CLAUDE.md — [NOMBRE DEL PROYECTO]

La ley de este repo vive en un solo lugar: @AGENTS.md

## Específico de Claude Code

- Cambios multi-archivo o de enfoque incierto: plan mode primero (Explore → Plan → Implement → Commit). Fixes de una línea: directo.
- Features grandes: entrevistame con AskUserQuestion hasta cubrir los casos difíciles → escribí la spec en `specs/<feature>/spec.md` → ejecutala en sesión fresca.
- Antes de commits importantes: `/verify` (probar end-to-end) y `/code-review` (revisión en contexto fresco).
- Investigaciones amplias del codebase: subagentes, para no llenar el contexto principal.
