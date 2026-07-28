# docs/adr/ — decisiones técnicas

Una decisión = un archivo: `NNN-titulo-corto.md`. Formato mínimo:

```markdown
---
type: ADR
title: "NNN — [Decisión en una frase]"
description: "[Una oración: qué decide este ADR.]"
---

# NNN — [Decisión en una frase]
- **Fecha:** YYYY-MM-DD
- **Contexto:** qué problema obligó a decidir
- **Opciones:** qué se consideró
- **Decisión:** qué se eligió y por qué
- **Consecuencias:** qué se acepta a cambio
```

> El frontmatter (`type`/`title`/`description`) es opcional pero recomendado: ayuda a los agentes a navegar los docs. Vocabulario alineado con el [Open Knowledge Format v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog) (usamos solo el núcleo estable — sin `generated`/`index.md`/maquinaria).

Se registra cuando la decisión sea cara de revertir (base de datos, arquitectura, dependencia central). Las triviales no.
