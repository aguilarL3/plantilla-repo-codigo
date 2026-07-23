---
type: Bitacora
title: "Bitácora de agentes"
description: "Handoff cronológico entre sesiones de agente en este repo."
---

# Bitácora de agentes

Handoff entre sesiones. Al cerrar una sesión con trabajo hecho, agregá tu entrada **al final** (la más reciente siempre abajo). Una entrada por sesión; si seguís trabajando, ampliá la tuya.

Formato:

```markdown
## YYYY-MM-DD — [agente] (rama: [rama])
- **Qué se avanzó:** (con estado de tests: en verde / rotos / no corridos)
- **Qué quedó bloqueado:**
- **Qué se decidió:** (si es técnica cara de revertir → también a docs/adr/)
- **Qué debe saber el próximo agente:**
```

**Por qué el encabezado lleva agente y rama.** Este archivo está marcado `merge=union` en `.gitattributes`: cuando dos ramas lo tocan, git conserva las líneas de las dos en vez de marcar conflicto. Eso elimina el conflicto en cada merge, pero tiene dos consecuencias al leer:

- **Tras un merge, el orden del archivo no es confiable.** Union no ordena cronológicamente. Manda la fecha del encabezado, no la posición.
- **Con trabajo en paralelo esto no es una continuación, es contexto.** Si varios agentes o personas trabajaron a la vez, las últimas entradas son hilos distintos entremezclados: leelas como *estado del repo*, no como *dónde quedó tu tarea*.

---
