<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · **🇪🇸 Español** · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Una aplicación ligera para la barra de menús de macOS que muestra cuánto has consumido de tus límites de **Claude**, **Codex** y **Cursor**, además de estadísticas de tokens y lo que costaría el mismo uso a través de las API públicas.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Características

- **Límites de un vistazo**: ventanas de 5 horas y semanales para Claude y Codex, pools de uso incluidos para Cursor, cada uno con barra de progreso, tiempo restante hasta el reinicio y fecha exacta.
- **Límites semanales por modelo** para Claude (Opus, Sonnet, Fable, …) en cuanto la API los informa.
- **Estadísticas de uso**: tokens por tipo, coste, desglose por modelo y por proyecto, gráfico diario; Hoy / 7 días / 30 días / Todo.
- **Notificaciones** cuando un límite supera un umbral, con un valor global y reglas por límite (silenciar, umbral propio).
- **Actualización automática** opcional, inicio al iniciar sesión, 17 idiomas de interfaz.
- **Actualizaciones remotas** desde GitHub Releases, verificadas con SHA-256.
- **Sin cuentas ni telemetría.** AgentBar lee los tokens que los clientes oficiales ya guardan en tu Mac y solo se comunica con las API de los propios proveedores.

## Requisitos

- macOS 14 Sonoma o posterior (Apple Silicon o Intel).
- Al menos uno de estos clientes con sesión iniciada: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI o aplicación), [Cursor](https://cursor.com). Los proveedores que no uses se pueden ocultar en Ajustes.

## Instalación

1. Descarga `AgentBar.zip` desde la [última versión](https://github.com/funbool/agentbar/releases/latest).
2. Descomprímelo y mueve `AgentBar.app` a `/Applications`.
3. Abre la aplicación. Se registra como elemento de inicio (puedes desactivarlo en Ajustes).

**Gatekeeper.** Las versiones están firmadas ad hoc, sin notarizar. Si macOS se niega a abrir una copia recién descargada, haz clic derecho → *Abrir* una vez, o elimina el atributo de cuarentena:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Aviso del llavero.** En la primera actualización de Claude, macOS pregunta si `security` puede leer el elemento *Claude Code-credentials*. Elige **Permitir siempre**. El aviso puede reaparecer después de que Claude Code rote su token; es normal.

También puedes [compilar desde el código fuente](#compilar-desde-el-código-fuente).

## Cómo funciona

AgentBar nunca pide iniciar sesión. Lee las credenciales que cada cliente ya guarda en tu Mac y llama a los mismos endpoints que usan los clientes.

| Proveedor | Credenciales leídas de | Endpoint | Qué se muestra |
|---|---|---|---|
| Claude | Elemento del llavero `Claude Code-credentials` (leído con `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | Ventana de 5 h, ventana semanal, límites semanales por modelo |
| Codex | `~/.codex/auth.json` (o `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | Ventana de 5 h, ventana semanal, plan |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (solo lectura) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Pool de modelos de Cursor (Auto / Composer / Grok), pool de modelos API, gasto bajo demanda, Grok Bot semanal, gasto del ciclo |

AgentBar no renueva tokens. Si un proveedor muestra *sesión caducada*, abre ese cliente una vez: renovará el token y AgentBar lo tomará en la siguiente actualización.

## El panel

- Haz clic en el icono de la barra de menús: todos los proveedores se actualizan al instante; mientras carga se muestran los valores anteriores.
- Las barras son verdes por debajo del 60 %, amarillas por encima y rojas al alcanzar el umbral de notificación.
- Cada límite muestra el tiempo restante y el momento exacto del reinicio, p. ej. *se reinicia en 2h 15m · jue 24 sept 20:00*.
- La campana junto a un límite abre su regla de notificación (activar/desactivar, umbral).
- Pie del panel: estadísticas · actualizar · ajustes · salir.

## Estadísticas de uso

El botón de gráfico del pie abre la ventana de estadísticas. Arriba cambias de proveedor y periodo; al pasar el cursor por el gráfico ves el total del día o la parte de un modelo concreto.

| Proveedor | Fuente | Coste |
|---|---|---|
| Claude | Transcripciones de Claude Code (`~/.claude/projects/**/*.jsonl`), indexadas una vez y cacheadas por archivo | Lo que costaría el mismo uso mediante la API: entrada/salida a precio de lista, escrituras de caché ×1,25 (TTL 5 min) / ×2 (TTL 1 h), lecturas de caché ×0,1 |
| Codex | Registros de sesiones (`~/.codex/sessions/**/*.jsonl`) | Precios de lista de la API de OpenAI; entrada en caché ×0,1. Los modelos sin precio público solo muestran tokens |
| Cursor | Eventos de uso del panel de Cursor, cacheados localmente. Al abrir por primera vez eliges cargar todo el historial o solo el ciclo de facturación actual; después solo se descargan eventos nuevos | Según lo informa Cursor por cada solicitud |

**Por qué los totales de Claude en AgentBar difieren de `/stats` en Claude Code.** Claude Code cuenta cada línea de la transcripción, y una respuesta con varios bloques (razonamiento, texto, llamadas a herramientas) se escribe como varias líneas que comparten el mismo registro de uso, así que se cuenta varias veces. AgentBar cuenta cada respuesta una sola vez con los valores finales —lo que realmente factura la API— y muestra al lado la cifra de Claude Code como referencia.

Indexar 700 MB de transcripciones tarda unos 10 segundos la primera vez y mucho menos de un segundo después. Las cachés están en `~/Library/Application Support/AgentBar/`.

## Notificaciones

- Activa las notificaciones en Ajustes → Notificaciones y elige un umbral por defecto (50–95 %).
- Cualquier límite puede silenciarse o recibir su propio umbral, desde Ajustes o desde la campana del panel.
- Recibes una notificación por límite y ciclo de reinicio.
- Los límites se comprueban en cada actualización: según la programación si la actualización automática está activa; si no, solo al abrir el panel.

## Ajustes

- **General**: intervalo de actualización (desactivado / 1 / 5 / 15 / 30 / 60 min), proveedores visibles, idioma, inicio al iniciar sesión, actualizaciones.
- **Notificaciones**: interruptor global, umbral por defecto, reglas por límite.

## Actualizaciones

AgentBar consulta GitHub Releases una vez al día y cada vez que pulsas *Buscar actualizaciones*. Cuando hay una versión más reciente, el panel muestra un botón *Actualizar*. La actualización se descarga, se verifica su SHA-256 contra la suma publicada, se comprueban el identificador del bundle y la versión, la aplicación antigua va a la Papelera y se lanza la nueva. También puedes instalar cualquier versión a mano desde la [página de versiones](https://github.com/funbool/agentbar/releases).

## Compilar desde el código fuente

Requiere Xcode 15 o posterior (Swift 5.9). Sin dependencias de terceros.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # pruebas unitarias
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # compilar, copiar a /Applications y lanzar
```

Utilidades de depuración (ejecuta el binario del bundle o `.build/debug/AgentBar`):

```bash
AgentBar --dump            # consultar cada proveedor una vez y mostrar los límites analizados
AgentBar --raw             # mostrar el JSON sin procesar de cada endpoint
AgentBar --stats           # indexar los registros locales de Claude/Codex y mostrar totales
AgentBar --cursor-events   # descargar eventos de uso de Cursor y mostrar totales
AgentBar --update          # ejecutar el ciclo completo de actualización sin interfaz
```

### Publicar una versión

```bash
./scripts/release.sh 0.2.0
```

Esto sube la versión en `Packaging/Info.plist`, crea la etiqueta `v0.2.0` y hace push. GitHub Actions ejecuta las pruebas, compila la aplicación, publica `AgentBar.zip` y `AgentBar.zip.sha256` como versión, y las copias en ejecución la detectan en su siguiente comprobación.

## Privacidad y seguridad

- **Lee:** el elemento del llavero de Claude Code, `~/.codex/auth.json`, el `state.vscdb` de Cursor (solo lectura), transcripciones y registros de sesión locales.
- **Escribe:** preferencias y cachés en `~/Library/Application Support/AgentBar/`.
- **Red:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (tus propios datos de uso) y `api.github.com` / `github.com` (comprobación y descarga de actualizaciones). Nada más.
- Las versiones las compila GitHub Actions a partir del código etiquetado; el flujo está en `.github/workflows/release.yml`.

## Solución de problemas

| Síntoma | Qué hacer |
|---|---|
| *Sin sesión — abre …* | Inicia sesión en ese cliente una vez; AgentBar leerá el token guardado en la siguiente actualización. |
| El aviso del llavero aparece una y otra vez | Elige *Permitir siempre*. Un nuevo aviso pasado un tiempo significa que Claude Code rotó su token. |
| Cursor no muestra nada | Abre Cursor una vez para que renueve su token de sesión y luego actualiza AgentBar. |
| La app no se abre tras descargarla | Gatekeeper — consulta [Instalación](#instalación). |
| Las estadísticas se quedan en *Indexando…* | La primera indexación de carpetas grandes tarda un rato; las siguientes usan la caché. |

## Agradecimientos

La investigación de los endpoints se apoyó en el proyecto de código abierto [CodexBar](https://github.com/steipete/CodexBar).

## Licencia

[MIT](../LICENSE)
