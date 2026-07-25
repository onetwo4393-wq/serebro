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

## Proyecto

- **Generador:** Zola (static site generator)
- **Templating:** Jinja2
- **Styling:** CSS custom + dark mode
- **Hosting:** Netlify (automatic deploys)

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
