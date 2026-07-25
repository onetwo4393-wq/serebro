# Ser Ebro En Los Deportes

Periodismo deportivo de **Boxeo, UFC y MMA** — análisis sin filtro desde adentro de la jaula.

**Sitio en vivo:** https://portal-serebro.netlify.app

## Stack

- **Generador:** [Zola](https://www.getzola.org/) (static site)
- **Templating:** Jinja2
- **Estilo:** CSS custom + Dark mode
- **Deploy:** Netlify (automático en push a main)

## Desarrollo Local

### Requisito

Zola instalado. Ver [getzola.org/documentation/getting-started/installation](https://www.getzola.org/documentation/getting-started/installation/)

### Arranca

```bash
zola serve
# http://localhost:1111
```

El sitio recompila automáticamente cuando editas archivos.

## Estructura

```
content/          Artículos (Markdown + frontmatter)
├── boxeo/
├── mma/
├── ufc/
└── protagonistas/

templates/        HTML con Jinja2
├── base.html     Template padre
├── macros.html   Componentes reutilizables
└── [layouts]     Layouts específicos

static/assets/    CSS e imágenes
├── css/
│   ├── style.css      Estilos principales
│   └── dark-mode.css  Overrides para dark mode
└── img/               Imágenes (webp)

zola.toml        Configuración del sitio
```

## Agregar Contenido

```bash
# Crear artículo
cat > content/boxeo/nuevo.md << 'EOF'
+++
title = "Título"
date = 2026-07-25
slug = "nuevo"
+++

Contenido aquí.
EOF
```

**Frontmatter obligatorio:** `title`, `date`, `slug`

## Para Más Info

- **CLAUDE.md** — Cómo usar este laboratorio
- **ARCHITECTURE.md** — Por qué hacemos las cosas así
