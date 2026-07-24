# Ser Ebro En Los Deportes

Periodismo deportivo de **Boxeo, UFC y MMA** — análisis sin filtro desde adentro de la jaula.

**Sitio:** https://portal-serebro.netlify.app

---

## Stack

- **Generator:** [Zola](https://www.getzola.org/) (Rust)
- **Templating:** Jinja2
- **Styling:** CSS custom + Dark mode
- **Hosting:** Netlify
- **Deployment:** Git push (automatic)

---

## Desarrollo Local

### Setup
```bash
# Instalar Zola (macOS)
brew install zola

# En el repo
zola serve
# → http://127.0.0.1:1111
```

### Compilar para produción
```bash
zola build
# → Genera /public/
```

---

## Estructura

```
content/           Artículos y páginas
├── boxeo/         Artículos de boxeo
├── mma/           Artículos MMA
├── ufc/           Artículos UFC
└── protagonistas/ Perfiles de peleadores

templates/         HTML Jinja2
├── base.html      Template padre
├── macros.html    Componentes reutilizables
└── [secciones]    Layouts específicos

static/assets/     CSS, imágenes
├── css/           Estilos (style.css, dark-mode.css)
└── img/           Imágenes (webp)

scripts/           Bash scripts
├── ingesta_*.sh   Scripts de ingesta de YouTube/datos
└── cleanup-*.sh   Utilidades
```

---

## Agregar Contenido

### Crear un artículo nuevo

```bash
# Crear archivo en content/[seccion]/slug.md
cat > content/boxeo/nuevo-articulo.md << 'EOF'
+++
title = "Título del Artículo"
date = 2026-07-24
slug = "nuevo-articulo"
+++

Contenido markdown aquí.
EOF
```

### Frontmatter obligatorio
- `title` — Título del artículo
- `date` — Fecha en formato YYYY-MM-DD
- `slug` — URL friendly (slug)

---

## Cambiar Diseño

- **Header/Footer:** Editar `templates/base.html`
- **Colores:** Editar `static/assets/css/style.css` (variables CSS)
- **Dark mode:** Editar `static/assets/css/dark-mode.css`
- **Componentes:** Editar `templates/macros.html`

👉 **Ver [CLAUDE.md](CLAUDE.md) para detalles y convenciones.**

---

## Deployment

Netlify está configurado para:
- ✅ Build automático en push a `main`
- ✅ Deploy automático a producción
- ⚠️ **NO hacer `git push` sin revisar localmente**

---

## Contribuir

1. Crear rama: `git checkout -b fix/issue-name`
2. Hacer cambios
3. Test local: `zola serve`
4. Commit: `git commit -m "type: msg"`
5. **Revisar antes de push**

---

## Soporte

- **Errores de build:** Ver `zola build` output
- **Estructura:** Revisar [CLAUDE.md](CLAUDE.md)
- **Auditoría completa:** Ver [AUDIT.md](AUDIT.md)

---

**Última actualización:** 2026-07-24
