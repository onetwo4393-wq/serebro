# CLAUDE.md — Guía del Laboratorio

## Setup Inicial

```bash
# Compilar el sitio
zola build

# Servir en desarrollo (hot reload)
zola serve  # http://127.0.0.1:1111
```

---

## Estructura del Proyecto

```
workspace/
├── content/          → Artículos .md (Zola content)
│   ├── boxeo/        → Boxeo
│   ├── mma/          → MMA
│   ├── ufc/          → UFC
│   ├── protagonistas/→ Perfiles de peleadores
│   └── [más secciones]
├── templates/        → HTML Jinja2
│   ├── base.html     → Template padre (header, footer, etc.)
│   ├── macros.html   → Componentes reutilizables
│   ├── seccion.html  → Página de sección
│   └── [más templates]
├── static/assets/    → CSS, imágenes, fonts
│   └── css/          → style.css (main), dark-mode.css
├── scripts/          → Bash scripts (ingesta de datos)
├── public/           → Build compilado (gitignore)
└── zola.toml         → Configuración
```

---

## Qué Editar Según la Tarea

| Tarea | Archivos |
|-------|----------|
| Cambiar colores/fuentes | `static/assets/css/style.css` |
| Cambiar header/footer | `templates/base.html` |
| Cambiar layout de sección | `templates/seccion.html` |
| Agregar componente HTML | `templates/macros.html` |
| Agregar dark mode | `static/assets/css/dark-mode.css` |
| Agregar artículo | `content/[seccion]/nombre.md` |
| Cambiar home | `templates/index.html` |

---

## Convenciones CSS

- **Clases:** lowercase con guion (`nav-link`, `carta-peleador`)
- **Variables CSS:** `--variable-name` en `:root`
- **Media queries:** Mobile-first (pequeño → grande)
- **Colores:** Usar variables siempre (`var(--accent)`, `var(--color-dorado)`)

**Variables principales:**
```css
--bg-body:      #F0E3CF       /* Fondo principal */
--text-main:    #1a1814       /* Texto oscuro */
--accent:       #d20a0a       /* Rojo deportivo */
--color-dorado: #c9a84c       /* Dorado */
```

---

## Convenciones HTML/Jinja2

- **Semantic HTML:** `<header>`, `<nav>`, `<main>`, `<footer>`
- **ARIA labels:** Agregar en nav/buttons (`aria-label="..."``)
- **Templates:** Usar `{% extends "base.html" %}` + bloques `{% block content %}`
- **Macros:** Importar con `{% import "macros.html" as macros %}`

---

## Comandos Comunes

```bash
# Compilar y verificar errores
zola build

# Servir + hot reload (desarrollo)
zola serve --interface 127.0.0.1 --port 9999

# Ver cambios locales
git status
git diff

# Commit (después de editar)
git add <archivo>
git commit -m "feat/fix/docs: mensaje claro"

# Ver últimos commits
git log --oneline -10

# Buscar en código
grep -r "texto" templates/
find . -name "*.html" -type f
```

---

## Permisos Actuales

✅ **Habilitados:**
- Zola serve/build
- Git add/commit/config
- Bash general
- Read/Edit/Write (para este CLAUDE.md)

⚠️ **Limitados (requieren permiso):**
- `git status`, `git log`, `git branch` (configurables)
- `grep`, `find` (configurables)

📝 **Para expandir:** Editar `.claude/settings.local.json`

---

## Git Workflow

1. Editar archivo(s)
2. `git add archivo`
3. `git commit -m "type: descripción"` (type = feat/fix/docs/style/chore)
4. Revisar con `git log --oneline -1`
5. **NO hacer `git push`** (manual review)

---

## Tips de Eficiencia

- Zola serve corre en background: `zola serve &`
- Las imágenes .webp son estándar (no .jpg)
- CSS está en un archivo (fácil de buscar)
- Frontmatter de content: `title`, `date`, `slug` son obligatorios
- Dark mode se activa con CSS disabled/enabled en el mismo archivo

---

## Problemas Comunes

| Problema | Solución |
|----------|----------|
| Header se ve roto | Revisar `templates/base.html` y `static/assets/css/style.css` |
| Imágenes no cargan | Verificar ruta en content: `/assets/img/...` (absoluta) |
| Cambios no se ven | `zola build` después de editar templates |
| Git bloqueado | Configurar permisos en `.claude/settings.local.json` |

---

**Última actualización:** 2026-07-24  
**Versión:** 1.0
