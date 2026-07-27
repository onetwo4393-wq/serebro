# CLAUDE.md — Entrada del Laboratorio

Bienvenido. Este archivo te orienta sobre el laboratorio.

## Estructura

- **README.md** — Qué es SerEbro (descripción del proyecto)
- **ARCHITECTURE.md** — Por qué hacemos las cosas así (decisiones de diseño)
- **WORK_CONTRACT.md** — Cómo trabajamos juntos (ver `/root/.claude/WORK_CONTRACT.md`)

## Flujo Típico

```
zola serve --interface 0.0.0.0 --port [port]
# Editar archivos
git add [archivo]
git commit -m "type: descripción"
# Verificar en navegador
```

### ⚠️ CSS Workflow: Verificación Obligatoria

Cambios CSS (especialmente responsive) **SIEMPRE** verificar EN NAVEGADOR antes de reportar.

**Problema:** "Agregué media query" no significa "funciona". Cascade CSS silencioso puede pisar cambios.

**Workflow:**
1. Editar CSS en `static/assets/css/style.css` (o `dark-mode.css`)
2. Servidor recompila automático (hot-reload)
3. **ABRE DevTools:** `F12` o `Ctrl+Shift+I`
4. **Viewport mobile (375px):** Redimensiona o usa device mode
5. **Selecciona elemento cambiado:** Click derecho → Inspect
6. **Verifica en "Computed" tab:** ¿Qué regla CSS ganó? ¿Es la que esperás?
7. Probá en otros viewports (768px tablet, 1024px desktop)
8. **RECIÉN ENTONCES:** `git commit` y reportar

**Qué buscar en Computed:**
- ✅ Regla nueva tiene ✓ check, sin tachado
- ❌ Regla nueva tiene ~ (override) — cascade le pisó
- ⚠️ Regla anterior en gris tachado — fue reemplazada

**Shortcut:** Media query no funciona → Lee ARCHITECTURE.md sección "CSS Cascade en Media Queries"

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

## Comandos Esenciales

```bash
zola build          # Compilar sitio
zola serve          # Servidor local + hot-reload
git status          # Ver cambios
git log --oneline   # Ver commits
```

## Configuración Local

**`.claude/settings.local.json`** — Define qué comandos Bash permitir sin confirmación.

Contiene una lista de patrones autorizados para:
- `zola serve`, `zola build` (desarrollo)
- `git add`, `git commit`, `git branch` (versionado)
- `curl`, `grep`, `sed` (utilidades)
- `pkill`, `sleep`, `echo`, `cat` (control)

**No modificar** a menos que necesites agregar nuevos comandos autorizados.

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
