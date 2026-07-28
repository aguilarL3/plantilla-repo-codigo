# docs/adr/ — decisiones técnicas

Una decisión = un archivo: `NNN-titulo-corto.md`. Formato mínimo:

```markdown
---
type: ADR
title: "NNN — [Decisión en una frase]"
description: "[Una oración: qué decide este ADR.]"
generated:
  by: process:claude-code
  at: 2026-07-28T00:00:00Z
---

# NNN — [Decisión en una frase]
- **Fecha:** YYYY-MM-DD
- **Contexto:** qué problema obligó a decidir
- **Opciones:** qué se consideró
- **Decisión:** qué se eligió y por qué
- **Consecuencias:** qué se acepta a cambio
```

> Frontmatter [Open Knowledge Format v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog): `type`/`title`/`description` + `generated: {by, at}` (`by` = actor `process:<agente>` o `human:<usuario>`; `at` = datetime ISO 8601 de la última edición de fondo). Es opcional pero recomendado: ayuda a los agentes a navegar los docs. Sin `index.md` ni maquinaria — `README.md` es la guía de cada carpeta.

Se registra cuando la decisión sea cara de revertir (base de datos, arquitectura, dependencia central). Las triviales no.
