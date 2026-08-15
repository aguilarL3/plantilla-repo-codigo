---
type: Plan
title: "Plan 000 — [nombre de la feature]"
description: "[Una oración: cómo se implementa la feature de spec.md.]"
generated:
  by: process:claude-code
  at: 2026-08-13T00:00:00Z
---

# Plan 000 — [nombre de la feature]

> El CÓMO técnico: arquitectura, archivos a tocar, contratos de datos, dependencias y riesgos. Deriva de `spec.md`.

## Enfoque
[Arquitectura de la solución en 3-5 líneas: patrón de diseño, capas involucradas.]

## Archivos e interfaces
[Qué se crea/modifica, con rutas exactas:]
- `src/models/...` — [nuevo/modificado]
- `src/services/...` — [nuevo/modificado]
- `tests/...` — [suite de pruebas asociadas a R1..Rn]

## Modelo de datos
[Tablas/campos/relaciones nuevos o modificados. Omitir si la feature no toca base de datos.]

## Integraciones y contratos
[APIs, servicios externos o librerías nuevas, con sus modos de fallo y timeouts.]

## Riesgos y alternativas descartadas
[Qué alternativas técnicas se evaluaron y por qué se descartaron. Si una decisión es cara de revertir → crear `docs/adr/`.]
