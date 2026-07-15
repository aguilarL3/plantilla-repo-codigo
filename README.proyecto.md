# [NOMBRE DEL PROYECTO]

> En el kickoff: completar este archivo y **renombrarlo a `README.md`** (pisando el README de la plantilla, que ya cumplió su función).

[Qué es, en 2-3 líneas. Para el detalle de producto: `docs/product/`.]

## Correr el proyecto

```bash
bash setup.sh        # una vez por clon: activa el gate pre-commit + chequea requisitos
[instalar deps]      # completar según stack
[correr en dev]
[correr tests]
```

Requisitos: Git Bash (Windows) y Python para los hooks de seguridad; [+ los del stack].

## Estructura

- `src/` — el código
- `specs/` — specs por feature (qué → cómo → tareas)
- `docs/product/` — PRD y decisiones de producto (snapshot del vault dueño)
- `docs/adr/` — decisiones técnicas
- `docs/BITACORA.md` — handoffs entre sesiones de agente

## Trabajar con agentes

La ley del repo está en `AGENTS.md` (Claude Code la lee vía `CLAUDE.md`). Config **personal/local** (no committeada) en `.claude/settings.local.json`: allowlist propia de permisos y, si sos el operador dueño del vault, `additionalDirectories` para consultas ad-hoc al vault de la misma esfera — el repo nunca la requiere para funcionar.
