# CLAUDE.md — Entrada del Laboratorio

Bienvenido. Este archivo te orienta sobre el laboratorio.

## Estructura

- **README.md** — Qué es SerEbro (descripción del proyecto)
- **ARCHITECTURE.md** — Por qué hacemos las cosas así (decisiones de diseño)
- **ENVIRONMENT.md** — Qué puede y no puede hacer el sandbox (herramientas, red)
- **HERRAMIENTAS.md** — Qué necesita el agente ahora y a futuro (el laboratorio crece más allá de SerEbro)
- **AUDITORIA_SONNET.md** — Auditoría técnica puntual (CSS, templates, contenido) que originó los audits de `make doctor`
- **WORKSPACE_MEJORAS.md** — Reflexión de proceso: qué faltó como herramienta durante varias sesiones de trabajo
- **WORK_CONTRACT.md** — Cómo trabajamos juntos (ver `/root/.claude/WORK_CONTRACT.md`)

## Reglas de Trabajo

- **Scope estricto:** solo trabajar con los archivos explícitamente mencionados en cada tarea. Si encontrás algo relacionado fuera del scope, documentalo al final del reporte pero NO lo toques.
- **Sugerencias al final:** las sugerencias van al final de cada tarea, nunca interrumpiendo el trabajo en curso.

## Flujo Típico

```
zola serve --interface 0.0.0.0 --port [port]
# Editar archivos
make doctor          # audits + smoke test (ver sección CSS Workflow)
git add [archivo]
git commit -m "type: descripción"
git push             # Cloudflare Pages deploya y ahí se valida visualmente
```

### ⚠️ CSS Workflow: Verificación

Este sandbox **no tiene navegador** (sin Playwright, sin acceso al registry de npm — ver `ENVIRONMENT.md`). La validación visual final la hace el humano en el deploy real de Cloudflare Pages, después del push. No bloquees un commit intentando "ver" el resultado vos mismo — no es posible en este entorno.

Lo que sí podés y debés garantizar antes de commitear es que la cascada CSS no se está pisando silenciosamente (el problema real detrás de casi todos los bugs visuales que tuvo este repo — ver `ARCHITECTURE.md` sección 2.1).

**Workflow:**
1. Editar CSS en `static/assets/css/style.css` (o `dark-mode.css`)
2. `make audit-css` (o `make doctor` para correr los 4 audits) — detecta selector duplicado o regla incondicional pisando un `@media`
3. `zola build` sin errores
4. `git commit` y en el mensaje/reporte indicá qué viewport y qué modo (light/dark) debería revisar el humano
5. `git push` — Cloudflare Pages deploya automático; el humano valida en el sitio real y avisa si algo no coincide

**Shortcut:** Si `audit-css` no detecta nada pero el humano reporta que "la media query no funciona" → releé `ARCHITECTURE.md` sección "CSS Cascade en Media Queries", puede ser un patrón que el script todavía no cubre.

## Proyecto

- **Generador:** Zola (static site generator)
- **Templating:** Jinja2
- **Styling:** CSS custom + dark mode
- **Hosting:** Cloudflare Pages (automatic deploys)

## Carpetas Principales

- `content/` — Artículos (Markdown)
- `templates/` — HTML Jinja2 (layout, componentes)
- `static/assets/` — CSS, imágenes
- `zola.toml` — Configuración
- `inbox/` — Bandeja de entrada para capturas/imágenes que el humano manda para procesar (no versionado, ver `.gitignore`). Ver workflow en `/root/.claude/WORK_CONTRACT.md`.

## Comandos Esenciales

```bash
zola build          # Compilar sitio
zola serve          # Servidor local + hot-reload
make doctor         # 4 audits (css, dark mode, build, frontmatter) — correr antes de commitear
git status          # Ver cambios
git log --oneline   # Ver commits
```

## Configuración Local

**`.claude/settings.local.json`** — Permisos del agente en este sandbox.

El humano configuró `Bash(*)`, `Edit(*)`, `Write(*)` (acceso total) a propósito, no por descuido. **El agente no debe modificar ni acotar estos permisos por su cuenta** — si en algún momento parece que hace falta más o menos restricción, se pregunta antes de tocar el archivo.

## Cómo Empezar Sesión

1. Lee ARCHITECTURE.md (decisiones vigentes)
2. Consulta WORK_CONTRACT.md (en `/root/.claude/`)
3. `git log --oneline -5` (qué pasó antes)
4. `zola serve` (arrancar servidor)
5. Trabaja

## Notas

- El contrato de trabajo está en `/root/.claude/WORK_CONTRACT.md`
- No agregues documentación sin consultar primero
- Mantén esto simple (una página máximo)
