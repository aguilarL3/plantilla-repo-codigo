# Cómo trabajamos en este repo

> **PLANTILLA — completá y renombrá a `COMO-TRABAJAMOS.md`.** Reemplazá `<...>`, borrá lo que no aplique y linkealo desde el `README`. `setup.sh` avisa que hay que leerlo cuando `REPO_MODE=equipo`.
>
> **Por qué existe este documento y no alcanza con `AGENTS.md`:** `AGENTS.md` lo leen los agentes; esto lo lee una **persona**, en diez minutos, antes de su primer commit. Y si el repo está en plan Free de GitHub —donde no hay reglas de rama— **este documento es el control**, no un complemento. Escribilo en lenguaje llano: si hace falta saber git para entenderlo, no sirve.

Este es el repositorio de código de **`<proyecto>`**. Lo usamos más de una persona, cada una desde su computadora y con su propio agente de IA.

Leelo una vez antes de tu primer cambio.

> [!IMPORTANT]
> **Qué nos frena de verdad.** *(ajustá según el plan de GitHub del repo)*
>
> - Con plan **Free** y repo **privado**, GitHub **no puede bloquear nada**: no impide escribir en la rama principal ni exige revisión. Las reglas de rama no están disponibles (`403 · "Upgrade to GitHub Pro or make this repository public"`). El único freno automático es el `pre-commit` **instalado en tu computadora** — y solo existe si hacés el paso 1.
> - Con plan **de pago** (o repo público) y las reglas activadas, GitHub además exige PR, revisión y checks en verde. Ahí esto es un resumen, no el control.

## 1. Una sola vez, al clonar

```bash
git clone <url-del-repo>
cd <proyecto>
bash setup.sh
```

`setup.sh` activa las verificaciones locales: te frena si estás por publicar un secreto, si intentás commitear en la rama principal, y (una vez cableada la suite) si rompiste los tests. **Si no lo corrés, no tenés ninguna red de seguridad.**

```bash
git config core.hooksPath      # tiene que responder: .githooks
```

Configurá tu identidad con el **mismo correo que verificaste en GitHub**:

```bash
git config user.email <tu-correo>
git log -1 --format='%ae'      # confirmá qué correo quedó
```

> Si tu correo no está **verificado** en GitHub (Settings → Emails), tus cambios aparecen sin tu nombre ni tu foto, y corregirlo después obliga a reescribir historial compartido. Hacelo **antes** del primer commit.

> ⚠️ **Si hay más de un repo del mismo proyecto** (por ejemplo un vault y este), van en carpetas **hermanas, nunca anidadas**: un repo dentro de otro se lo traga el de arriba.

## 2. El ritual de cada sesión

| Cuándo | Qué hacés |
|---|---|
| **Al abrir** | `git pull` — traés lo que hicieron los demás |
| **Antes de tocar nada** | `git switch -c <vos>/tema` — te movés a **tu rama** |
| **Al cerrar** | Publicás tu rama y abrís un **PR** para que otra persona lo mire |

**Prefijos de rama** — dos letras, no la inicial (en cuanto dos personas comparten inicial la convención se rompe):

| Persona | Prefijo | Ejemplo |
|---|---|---|
| `<Nombre Apellido>` | `<xx>/` | `<xx>/login-oauth` |
| `<Nombre Apellido>` | `<yy>/` | `<yy>/textos-home` |

```bash
git pull
git switch -c <xx>/mi-tema
git push -u origin <xx>/mi-tema
gh pr create          # o desde la web
```

## 3. Nunca commitees en la rama principal

`repo.conf` tiene `REPO_MODE=equipo`: el `pre-commit` **rechaza** cualquier commit sobre la rama principal y no lo crea.

> [!WARNING]
> **Esto te va a pasar y no es un error.** El commit se rechaza con un mensaje explícito. No se rompió nada: te falta crear tu rama. `git switch -c <vos>/tema` y volvés a commitear.

Se puede saltear con `--no-verify`: no lo hagas. Si creés que lo necesitás, avisá primero — casi siempre significa que hay otro problema.

## 4. Quién escribe dónde

**Ajustá esta tabla al reparto real.** Y separá dos cosas que se confunden: los **permisos** responden *"¿tiene derecho?"*; las **zonas** responden *"¿quién escribe este archivo hoy?"* — y eso no es confianza, es que **git no mezcla dos ediciones del mismo lugar**.

| Zona | Regla |
|---|---|
| `AGENTS.md`, `CLAUDE.md`, `repo.conf`, `.claude/`, `.githooks/`, `.github/` | **Avisá antes.** Es el único lugar donde tu cambio aparece como un **cambio de comportamiento en la computadora de la otra persona**: su agente empieza a trabajar distinto sin que nadie se lo haya pedido |
| Lockfiles y migraciones | **No se mergean a mano.** Regenerá el lockfile desde la rama principal ya integrada; renumerá tu migración. Un merge textual parece resuelto y no lo está |
| `specs/<feature>/` en curso | Una persona por spec a la vez |
| `docs/BITACORA.md` | Se **agrega al final**, nunca se reescribe la entrada de otro. Tiene `merge=union`: dos entradas en paralelo se conservan las dos |
| `<otras zonas del proyecto>` | `<regla>` |

**Ramas cortas: abrilas y cerralas el mismo día.** Si un trabajo va a llevar una semana, partilo.

## 5. Trabajar con tu agente de IA

La ley que obedecen está versionada en el repo (`AGENTS.md`, `CLAUDE.md`, `.claude/`): tu agente la lee solo. Tres reglas para vos:

1. **El autor del commit sos vos, no el agente.** El agente va de trailer. Un commit firmado por un robot es un commit del que nadie responde.
2. **Al PR llega una rama por persona, no una por agente.** Si corriste varios agentes en worktrees, los integrás localmente antes.
3. **Nadie aprueba su propio PR — ni el que hizo su agente.** Ese segundo par de ojos es lo único que reemplaza a los controles automáticos que no tenés.

Al cerrar una sesión con trabajo hecho, tu agente deja su entrada en `docs/BITACORA.md` con **agente y rama** en el encabezado. **La lee el agente de la otra persona**, así que se escribe para cualquiera del equipo.

> Con exactamente dos personas: cada PR lo revisa la otra, siempre, y no hay tercero de respaldo — si una no está, el PR espera. Es el costo de ser dos; conviene saberlo de entrada.

## 6. Lo que nunca va al repo

**Contraseñas, tokens, claves de API, datos personales de clientes.** Ni siquiera "un momentito para probar". Los secretos van a `.env`, gitignoreado.

Una vez publicado, **ya se filtró**: borrarlo no lo borra del historial, y hay que rotar la credencial. El `secret-scan` te va a frenar si lo detecta, pero no confíes en él — confiá en no ponerlo.

## 7. Cómo leer el check `verify` del PR

*(Borrá lo que no aplique.)*

- **¿Corre algo de verdad?** Hasta cablear lint y tests (kickoff paso 7), `verify` queda **verde sin correr una sola prueba**.
- **¿Bloquea?** Solo si el plan permite *"Require status checks to pass"* y está activado. En plan Free con repo privado, **no**: es señal, y un PR en rojo se mergea igual.
- **¿Se dispara solo?** Debería, con `pull_request`. Si no arranca, se puede lanzar a mano desde *Actions* → *verify* → *Run workflow*.

## 8. Si algo sale mal

- **Conflicto al mezclar:** no lo resuelvas a las apuradas. Avisá. Un conflicto mal resuelto borra el trabajo de alguien en silencio.
- **Rompiste algo y no sabés qué:** no borres nada. Git guarda todo; se recupera. Avisá.
- **Commiteaste sin querer en la rama principal:** avisá antes de tocar nada más.
- **El `pre-commit` te frena y no entendés por qué:** leé el mensaje completo antes de buscar cómo saltearlo. Casi siempre dice exactamente qué falta.

Ninguna de estas situaciones es un problema si se avisa temprano. Todas lo son si se tapan.

---

**El detalle técnico** está en `AGENTS.md`. Si el repo pertenece a un vault del Sistema Maestro, la referencia completa es `SOP Git y Flujo de Trabajo` §11–§12 y `SOP Proyectos de Código` §6.1.
