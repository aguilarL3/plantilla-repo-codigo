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

## 2026-08-06 — Claude Code (rama: main)

**Qué se hizo:** arreglado el mensaje del **gate de rama**, que es el texto de mayor impacto del repo — aparece en el momento exacto en que la persona se equivoca, cuando de verdad lo va a leer. Tenía los dos defectos que esta tanda viene corrigiendo en todos lados:

1. **Prometía controles que pueden no existir:** *"todo entra por PR, ahí corren CODEOWNERS y el workflow verify"*. `CODEOWNERS` puede no existir (la plantilla trae solo el `.example`) y sin reglas de rama —plan Free + repo privado— el `verify` del PR es **señal, no bloqueo**. El gate local suele ser el único control automático real, así que el mensaje ya no nombra controles de servidor que quizás no estén: dice *"ahí lo revisa la otra persona"*, que es lo que sí pasa.
2. **`git switch -c <inicial>/<tema>` con ejemplo `b/login-oauth`.** El prefijo va de **dos letras**; el mensaje ahora lo dice, explica por qué (dos personas que comparten inicial) y —si el archivo existe— remite a `COMO-TRABAJAMOS.md` §2 para saber cuál te toca.

**Verificado:** `bash -n` acá, y en la instancia (`perfiles-qr`) la **prueba real**: commit sobre `main` rechazado, commit no creado, y el mensaje nuevo impreso completo con el link al acuerdo.

**Qué debe saber el próximo agente:** el hook del seed y el de la instancia **divergen a propósito** en la parte de lint/tests (la capa código no viene en la plantilla), así que este arreglo **no se puede portar copiando el archivo** — se editan las mismas líneas en los dos. Si tocás el bloque del gate de rama, hacelo en ambos o quedan diciendo cosas distintas. Y la regla de fondo: **un mensaje de error que nombra controles opcionales miente la mitad de las veces**; nombrá solo lo que el propio gate garantiza.

## 2026-08-07 — Claude Code (rama: main)

**Qué se hizo:** portadas al seed las dos piezas que resuelven "¿cómo me entero de que hay un PR esperando?", surgidas de un caso real donde la respuesta era **de ninguna forma**.

**El hallazgo que las motiva, verificado contra la API:** `CODEOWNERS` **no auto-asigna revisor en repos privados con plan Free**. Tres PRs abiertos con el archivo completo y las dos personas listadas como code owners en **todas** las rutas quedaron con `requested_reviewers` **vacío**. Consecuencia: la vista *"te pidieron review"* de GitHub y de `gh pr status` queda **muerta**.

1. **`.claude/hooks/pr-notice.sh` + registro en `SessionStart`** — al abrir el agente, dice qué PRs abiertos esperan tu review y cuáles son tuyos esperando el review del otro. **No se apoya en review requests**, justamente porque no funcionan: lista los PR abiertos y separa por autor. Adaptado a las convenciones del seed: gate por `REPO_MODE` de `repo.conf` (**parseado, no sourceado**) y estado en `.repo-meta/`. Inerte en `solo`, fail-open completo, kill-switch `.repo-meta/pr-notice.disabled`. **Nota: el seed no tenía ningún hook de `SessionStart`** — este es el primero, así que el bloque es nuevo en `settings.json`.
2. **`.github/workflows/aviso-de-pr.yml`** — al abrirse un PR, comenta mencionando a quien tiene que revisar. Una **@mención notifica siempre**, sin depender del plan ni de que la persona siga el repo: es el rodeo exacto a la limitación del `CODEOWNERS`. Pero un ping pelado no agrega nada sobre el mail del *watching*, así que el comentario **marca además si el PR toca las rutas que cambian el comportamiento del agente** (`AGENTS.md`, `.claude/`, hooks, `repo.conf`, `setup.sh`…) — eso es lo que más fácil se pasa por alto en un diff.

**Tres decisiones de diseño del workflow que conviene no "simplificar":** (a) **sin `synchronize`** en el `on:`, porque cada push a la rama volvería a comentar; (b) **a quién mencionar se resuelve por API** (colaboradores con permiso de escritura, menos el autor) en vez de hardcodear handles — si entra o sale gente del equipo sigue estando bien solo; (c) **nunca falla el check**: todo con `|| true` y `exit 0`, porque un aviso roto no debe bloquear un PR. Y los valores entran por `env:`, **nunca interpolados con `${{ }}` dentro del `run:`** — un título de PR con comillas o `$(...)` se ejecutaría.

**Verificado:** `bash -n` y corrida real del hook con `REPO_MODE=solo` → silencioso, como corresponde.

## 2026-08-15 — Claude Code (rama: main)

**Qué se hizo:** corregidos los **contratos de los dos subagentes SDD** antes de commitearlos por primera vez. Las definiciones existían sin versionar desde el 08-13; una auditoría contra el repo encontró 8 huecos y este es el primer bloque de los tres. Deliberadamente **no se commiteó lo que ya estaba y después se arregló**: una capa con defectos conocidos no entra al historial solo porque ya estaba escrita.

**Los cuatro arreglos de fondo:**

1. **El `@reviewer` contaba archivos, no verificaba nada.** Su paso de trazabilidad decía *"localizá el test que valide `R<n>`"* — o sea que un test existiera y la suite diera verde. Pero el sesgo que justifica su existencia es justamente que **el implementador escribe el código y sus propios tests**: si malinterpretó un requisito, su test da verde igual. Verificar que el test *existe* no detecta eso. Ahora, por cada `R<n>`, debe responder tres cosas por escrito: dónde está el test, **qué afirma el assert** (citado), y **¿fallaría si el requisito se rompiera?** Con motivos de rechazo explícitos: test sin assert sobre el resultado, mock que se afirma a sí mismo, o assert más débil que el requisito. La frase que ordena el paso: *"que la suite esté verde no es evidencia de cobertura"*.
2. **`## Verificación de cierre` no la leía nadie.** El `spec.md` la define como la prueba end-to-end sin la cual la spec no está completa, pero el protocolo del revisor no la mencionaba. Pasa a ser el paso 7, el último gate antes del veredicto.
3. **Los agentes hardcodeaban `npm test` / `pytest` en una plantilla agnóstica de stack.** Un repo Python derivado heredaba agentes que hablaban de npm. Ahora `AGENTS.md` declara **`Suite completa (cierre)`** como única fuente del runner, y los dos agentes (más el `tasks.md` de ejemplo) la leen de ahí en vez de adivinar.
4. **Nadie movía la máquina de estados de `feature_list.json`.** Los 5 estados y las 3 reglas del manifiesto no tenían ejecutor: el implementador leía la precondición pero al cerrar no escribía nada, y el revisor aprobaba sin que nada pasara a `done`. `AGENTS.md` ahora declara **quién mueve cada arista**, con la regla que importa: `spec_ready → in_progress` es **solo del humano** — si un agente puede moverla, no hay puerta. Los subagentes nunca escriben `status`; el `@implementer` sí marca `[x]` en `tasks.md` (progreso verificable, no decisión).

**Además:** `CLAUDE.md` había reemplazado `/verify` y `/code-review` por el `@reviewer`. No son sustitutos y se restauraron los tres: **`@reviewer` mira conformidad con la spec, `/code-review` mira correctitud**. Una feature puede satisfacer los cuatro requisitos EARS y tener un off-by-one.

**Qué quedó sin resolver (riesgo residual, no cerrado):** el `@reviewer` se declara solo-lectura pero tiene `Bash`, con el que puede escribir, commitear y borrar. El formato de subagente soporta `tools:`, **no una deny-list por agente**, así que la mitigación aplicada es a nivel prompt: allowlist de comandos (`git diff/log/show` + la suite), prohibición nominal de las escrituras, y declaración obligatoria de *"no modifiqué ningún archivo"* en el veredicto. **Es exactamente el tipo de control que esta tanda critica** — obediencia, no enforcement — y por eso queda anotado y no dado por resuelto. Si aparece soporte de permisos por subagente, este es el lugar.

**Qué debe saber el próximo agente:** faltan los bloques 2 y 3. El **2 es el que cambia la naturaleza del control**: un `sdd-gate.sh` en `.githooks/pre-commit` que bloquee cuando una feature en `spec_ready` toca `src/`, y que le dé ejecutor a `one_feature_at_a_time` y `require_tests_to_close`. Hoy el freno de mano es prosa en markdown mientras el resto del repo se apoya en gates deterministas (secret-scan, gate de rama, deny-list) — esa asimetría es el hallazgo de fondo de la auditoría. El bloque 3 es onboarding: ni el `README` ni `setup.sh` mencionan `feature_list.json` ni `.claude/agents/`, así que quien derive el repo hoy no sabe que existen.

**Ampliación (misma sesión) — bloque 2: el gate deja de ser prosa.** Nuevo `.claude/hooks/sdd-gate.{sh,py}` (wrapper delgado + lógica en python, mismo patrón que `security-guard`), cableado en `.githooks/pre-commit` **antes** del secret-scan porque parsear un JSON es más barato que escanear el diff, y con contraparte informativa en `verify.yml` vía `--range`, igual que `secret-scan`.

**Lo que hace cumplir** son las reglas que `feature_list.json` ya declaraba y nadie ejecutaba: `require_approved_spec_to_implement` (código staged + una feature en `spec_ready` **y ninguna en `in_progress`** → bloquea), `one_feature_at_a_time` (dos en curso → bloquea) y `require_tests_to_close` (feature `done` con tasks `[ ]` → bloquea). Si el repo pone una regla en `false`, el gate no la aplica: **manda el manifiesto, no el hook**.

**Tres decisiones que conviene no "simplificar":**
- **La condición del gate lleva un `y ninguna en in_progress`.** Sin eso, tener una feature esperando aprobación mientras construís otra bloquearía todo commit de código — un falso positivo diario, y un gate que molesta sin motivo termina apagado.
- **`require_tests_to_close` solo se evalúa cuando `feature_list.json` entra en el commit.** Es cuando se está cerrando algo. Chequearlo siempre convertiría una casilla vieja sin marcar en un bloqueo permanente.
- **"Tocar código" se define por allowlist de lo que NO es código** (`specs/`, `docs/`, `.github/`, `.claude/`, `.githooks/`, `.md` de raíz, config conocida), no por `src/`. La plantilla es agnóstica de stack: un proyecto Python en `app/` o un Go en `cmd/` quedaban fuera del gate si se hardcodeaba `src/`. Probado explícitamente con `app/main.py`.

**Verificado (15 escenarios, repos git reales, 15/15):** inerte sin manifiesto · inerte con `sdd:false` · `pending` no bloquea · `spec_ready`+código bloquea · `spec_ready`+solo docs pasa · `spec_ready` con otra en curso pasa · dos `in_progress` bloquea · `done` con tasks abiertas bloquea (y no bloquea si el manifiesto no está staged) · `in_progress` sin `specs/` bloquea · kill-switch · JSON roto hace fail-open · regla en `false` no se aplica · nada staged pasa · código fuera de `src/` bloquea igual. Más prueba **en vivo en este repo**: con `000-ejemplo` movida a `spec_ready` y un `src/` de prueba, el `pre-commit` completo abortó con el mensaje correcto; estado restaurado después.

**Dos defectos que solo aparecieron corriéndolo:**
1. **Python en Windows codifica stderr con la codepage local**, así que el 🔴 salía como `\U0001f534` y los acentos como `?`. Los hooks en bash no lo sufren porque escriben UTF-8 crudo; el `.py` necesita `reconfigure(encoding="utf-8")` explícito. **Si escribís otro hook en python para este repo, arrancá por ahí.**
2. **El mensaje mentía en CI:** decía *"el commit no se hizo"* y ofrecía `--no-verify`, pero en un PR el commit ya existe. Ahora el encabezado y la salida de emergencia dependen del modo — la misma lección del gate de rama en agosto: **un mensaje que nombra controles que no aplican donde se lee, miente**.

**Qué debe saber el próximo agente:** el gate valida el manifiesto, pero **el manifiesto lo puede escribir un agente**. Nada impide hoy que quien implementa se auto-apruebe moviendo `spec_ready → in_progress` en el mismo commit donde mete el código. Es detectable (comparar el `status` staged contra el de `HEAD`) y está sin implementar. Igual de abierto: una feature en `pending` no da ninguna protección — el gate solo mira `spec_ready`. Resumen honesto de la cobertura actual: **el gate protege mientras el manifiesto sea sincero**. Falta también el bloque 3 (onboarding: ni `README` ni `setup.sh` mencionan `feature_list.json` ni `.claude/agents/`).

**Cierre — hallazgo de la auditoría, aplicado.** La auditoría de los dos bloques encontró que **el gate validaba un manifiesto que el propio agente puede escribir**: mover `spec_ready → in_progress` y meter el código en el mismo commit lo esquivaba entero (verificado: exit 0). O sea que el bloque 2 había movido la puerta de lugar, no cerrado.

El hook **no puede saber quién editó `feature_list.json`**, así que no distingue "el humano aprobó" de "el agente se aprobó solo" — y exigir lo contrario habría dado falsos positivos en el flujo normal (el humano aprueba y el agente implementa a continuación). Lo que sí puede exigir es que **la aprobación sea su propio commit**: si una feature pasa a `in_progress` en el mismo cambio que trae código, se bloquea con la instrucción exacta (`git commit feature_list.json -m "aprueba: <feature>"`). La decisión queda fechada y auditable en el historial en vez de disolverse dentro del commit del código. Documentado en `AGENTS.md`. Banco de pruebas ampliado a **19 escenarios (19/19)**, incluidos los dos falsos positivos que había que evitar: feature ya aprobada en un commit previo, y repo sin `HEAD`.

**Lo que sigue abierto, a conciencia:** una feature en `pending` **no da ninguna protección** — el gate solo mira `spec_ready`, porque bloquear en `pending` frenaría cada commit de un repo recién derivado (`000-ejemplo` nace ahí). Un agente que nunca escribe la spec nunca encuentra la puerta. Refinamiento posible sin romper el kickoff: bloquear solo si existe `specs/<feature>/`, o sea la spec escrita con el estado sin avanzar — ahí el `pending` es drift, no un repo nuevo. Tampoco hay `deny` en `settings.json` sobre `--no-verify` ni sobre escribir el manifiesto (y los patrones matchean por prefijo, así que `git commit -m x --no-verify` esquivaría la regla igual). **La cobertura real, dicha sin adornos: el gate protege mientras el manifiesto sea sincero, y ahora además deja rastro de cuándo dejó de serlo.**

**Ampliación 3 — bloque 3: la capa deja de ser invisible.** La capa SDD existía y funcionaba, pero **ninguna puerta de entrada la mencionaba**: quien derivara el repo no sabía que `feature_list.json` ni `.claude/agents/` existían, ni que había un gate que le iba a rechazar un commit. Agregado al `README`: tres filas en *Qué trae* (manifiesto, subagentes, `sdd-gate.sh` con su kill-switch), una línea en *Cómo se ve trabajar acá*, y una sección **Flujo spec-driven** que explica la pausa en lenguaje llano —incluido **qué NO cubre**, para que nadie se confíe de más—. El kickoff paso 7 ahora arranca por personalizar el manifiesto, y el 6 aclara que la suite se **declara** en `AGENTS.md` además de cablearse en los dos hooks. `setup.sh` avisa si el manifiesto quedó con el nombre de la plantilla adentro, y dice explícitamente que borrarlo deja todo inerte: **una capa opcional tiene que decir cómo se apaga, o no es opcional**.

**De paso, dos referencias cruzadas rotas** (mismo problema de fondo: la puerta de entrada mentía). El cableado de lint/tests es el **paso 6** del kickoff, pero `AGENTS.md` mandaba al paso 7 y la tabla del `README` al paso 5 — los tres apuntaban a lugares distintos y dos estaban mal. Ahora los cuatro archivos que lo nombran (`README`, `AGENTS.md`, `verify.yml`, `pre-commit`) dicen 6. Verificado con un grep de todas las referencias a pasos numerados; las demás (`README.proyecto.md` en el 5, y los pasos 4 y 5 del modo equipo) estaban bien y no se tocaron.

**Ampliación 4 — el banco de pruebas del gate entra al repo** (`.claude/hooks/sdd-gate.test.sh`, 19 escenarios, corre en ~5s). Los demás hooks no tienen tests y está bien: `secret-scan` y `security-guard` son patrones sobre texto. **`sdd-gate` es una máquina de estados** (5 estados × 4 reglas, con varias combinaciones donde lo correcto es NO bloquear), y su modo de falla es el peor: un gate que deja pasar lo que debía frenar **no avisa nunca**. Los casos están agrupados por intención, y los tres que más importan son los **falsos positivos** —feature ya aprobada en un commit previo, otra feature en curso, casilla vieja sin marcar—, porque un gate que molesta sin motivo termina apagado y ahí se pierde entero. El banco trae además una guarda propia: valida que el `feature_list.json` que genera sea JSON legible, porque al escribirlo pasó justo eso —un default mal citado producía JSON inválido, el gate hacía fail-open y **cinco casos "pasaban" por el motivo equivocado**.
