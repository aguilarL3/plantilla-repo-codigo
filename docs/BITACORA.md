---
type: Bitacora
title: "Bitácora de agentes"
description: "Handoff cronológico entre sesiones de agente en este repo."
generated:
  by: process:claude-code
  at: 2026-07-28T00:00:00Z
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

## 2026-08-06 — Claude Code (rama: main)

**Qué se hizo:** portadas al seed tres cosas que salieron de sumar una segunda persona a un repo real (`teo-pet-market/perfiles-qr`) — o sea, la primera vez que la capa de modo equipo se usó de verdad.

1. **Nuevo `COMO-TRABAJAMOS.example.md`** — plantilla del acuerdo de trabajo en lenguaje llano, para completar y renombrar cuando entra la segunda persona. Faltaba: el seed tenía `AGENTS.md` (que leen los agentes) y `CODEOWNERS.example` (que no controla nada), pero **nada que una persona pudiera leer en diez minutos antes de su primer commit**. Y con plan Free ese documento no acompaña al control: **es** el control.
2. **🔴 `setup.sh`, dos arreglos.** (a) `core.hooksPath` ahora se **verifica leyéndolo de vuelta y el script aborta con `exit 1`** si no quedó — cuando no hay reglas de rama en el servidor, este es el único control que existe, y un setup que imprime `[ok]` sin comprobarlo es exactamente el modo de falla que importa. (b) El bloque de *Settings → Rules* aclara que **en plan Free con repo privado esas reglas no existen** (`403 · "Upgrade to GitHub Pro or make this repository public"`): antes mandaba a la persona a una pantalla que no le va a funcionar, sin decirlo. El aviso de `CODEOWNERS` también dejó de sobrestimar lo que el archivo hace.
3. **`AGENTS.md`, dos frases que eran falsas o frágiles.** El prefijo de rama pasó de `<inicial>/<tema>` a **dos letras**, con el motivo escrito: en cuanto dos personas comparten inicial la convención se vuelve ambigua (pasó en el caso real — dos nombres con L) y quedan ramas que parecen de otro. Y la afirmación *"todo entra por PR, que es donde corren `CODEOWNERS` y el workflow `verify`"* se reemplazó por un callout que dice qué controles hay que **verificar** en cada repo, porque los tres se suelen dar por hechos y a menudo no están (CODEOWNERS ausente, reglas de rama inexistentes en Free, `verify` verde sin correr nada).

**Verificado:** `bash -n setup.sh` y corrida real completa. El `setup.sh` portado es el mismo archivo probado en `perfiles-qr` y no arrastra nada específico de esa instancia (grepeado).

**Qué debe saber el próximo agente:** el `README` del seed ahora ordena los pasos de modo equipo poniendo **`setup.sh` antes** de las reglas de rama, a propósito: cuando el servidor no puede ayudar, ese paso es el crítico. Si algún día se agrega detección automática del plan de GitHub, el lugar es el bloque de modo equipo de `setup.sh` — hoy no se hace porque exigiría red y `gh` autenticado en el clon de cada persona, y un setup que falla por eso es peor que un aviso bien redactado.
