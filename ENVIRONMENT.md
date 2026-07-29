# ENVIRONMENT.md — Qué puede y no puede hacer este sandbox

Inventario real, verificado a mano (no supuesto) el 2026-07-29. Existe para no perder una llamada entera redescubriendo por prueba y error algo que ya se sabía (pasó antes — ver `WORKSPACE_MEJORAS.md`).

## Red

- Hay proxy obligatorio: `http_proxy`/`https_proxy` apuntan a `127.0.0.1:8888`.
- `npm`/`npx` contra `registry.npmjs.org` devuelven **403 Filtered** — no se puede instalar ningún paquete nuevo de npm (confirmado con `npx playwright`).
- `curl` a `localhost`/`127.0.0.1` (servidor de `zola serve`) **sí funciona** en este entorno.
- No asumas acceso a internet en general — cualquier script que dependa de descargar algo en el momento va a fallar.

## Binarios disponibles

- `zola` (0.22.1), `node` (v20.20.2), `npm`, `npx`, `git`, `make`, `curl`, `grep`, `sed`, `find`.
- `pgrep` y `pkill` **no existen**. Para manejar el proceso de `zola serve` en background, usar el propio job control de bash (`&`, `$!`, `kill $PID`) en vez de `pkill`.
- No hay `stylelint` ni ningún linter de CSS instalado, y no se puede instalar (ver Red). El equivalente casero vive en `scripts/audit-css.sh`.
- **No hay navegador ni Playwright/Puppeteer disponible**, y no se puede instalar (403 contra npm). No hay forma de tomar un screenshot ni de inspeccionar el DOM/CSS renderizado desde este sandbox.

## Verificación visual

Por lo anterior, la verificación visual de cambios CSS/UI **no la hace el agente en este sandbox** — la hace el humano mirando el deploy real en Cloudflare Pages después del push. Ver `CLAUDE.md` sección "CSS Workflow" para el flujo completo. Lo que el agente sí puede y debe garantizar antes de commitear es que pase `make doctor` (cascada CSS, sincronización dark mode, build, frontmatter).

## Si algo de esto cambia

Si en una sesión futura alguno de estos puntos ya no es cierto (por ejemplo, se habilita acceso a npm o se agrega un browser a la imagen), actualizá este archivo — es más barato corregir una línea acá que perder una llamada completa re-descubriéndolo.
