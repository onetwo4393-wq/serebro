# HERRAMIENTAS.md — Qué necesito para trabajar en este laboratorio

Este doc responde a un pedido puntual del usuario (2026-07-29): qué herramientas necesito ahora y a futuro, sabiendo que este workspace no va a ser solo SerEbro — la idea es usarlo como laboratorio para más sitios (periodistas deportivos, oficios/profesiones, béisbol, etc.), probablemente todos con el mismo stack (Zola + Jinja2 + CSS custom + Cloudflare Pages).

## Ya tengo, sin pedir nada

- **WebSearch / WebFetch** — corren por infraestructura de Anthropic, no por el proxy del sandbox. Puedo buscar referencias de diseño, sitios de la competencia o documentación aunque `npm` esté bloqueado.
- **ImageMagick (`convert`/`identify`)** — soporta lectura/escritura de WEBP. Puedo recortar, redimensionar y convertir imágenes ya mismo. Lo que NO puedo hacer es edición generativa (quitar una marca de agua tipo inpainting) — eso sigue siendo trabajo tuyo con Gemini/Nano Banana u otra herramienta de IA de imagen.
- El patrón `scripts/audit-*.sh` + `make doctor` + CI — ya reusable tal cual para el próximo sitio si arranca del mismo stack.

## Necesito ahora, pero está bloqueado en este sandbox (no es algo que puedas resolver vos desde el chat)

- **Navegador headless (Playwright/Puppeteer)** — sigue siendo el gap más grande para verificación visual real desde el agente. Bloqueado porque `npm` devuelve 403 contra el registry. Ya lo resolvemos hoy con vos validando en Cloudflare Pages, pero si en algún momento se puede habilitar a nivel de imagen del sandbox, cambia bastante lo que puedo garantizar antes de un commit.
- **Linter de CSS real (Stylelint)** — mismo bloqueo de red. Hoy lo reemplazo con el script casero (`audit-css.sh`), que cubre los patrones de bug que ya vimos pero no es un linter genérico.

## Lo que probablemente necesite en unos meses (cuando haya un segundo/tercer sitio)

- **Un starter kit / theme reusable** — extraer de SerEbro lo que no es específico de boxeo/UFC (macro de tarjetas, paleta base en `:root`, toggle de dark mode, el patrón de header overlay, los 4 scripts de audit + Makefile + CI) a una plantilla base, en vez de copiar-pegar carpeta por carpeta cada vez que arranca un sitio nuevo.
- **El workflow de CI como "reusable workflow"** de GitHub Actions, para no mantener una copia de `doctor.yml` por repo.
- **Un validador de frontmatter parametrizable** — `audit-frontmatter.sh` hoy conoce los campos de SerEbro (`nacionalidad`, `rating`). Para que sirva en un sitio de oficios/profesiones o béisbol sin reescribirlo, necesita leer su esquema de un config en vez de tenerlo hardcodeado.
- **Un script de scaffolding** (`scripts/new-site.sh <nombre>`) que clone el starter kit de arriba y ajuste `zola.toml`/estructura de `content/` para el nicho nuevo.
- Si en algún momento querés que yo mismo cree/gestione el proyecto de Cloudflare Pages de un sitio nuevo (no solo el código), voy a necesitar un token de API de Cloudflare con permisos acotados a Pages — no hace falta ahora, lo menciono para cuando llegue ese momento.

## Mi opinión sobre cómo organizar esto

- **Un starter kit, muchos repos** — no un monorepo con todos los sitios adentro. Son nichos sin relación de contenido entre sí (deportes, oficios, béisbol); un monorepo solo acoplaría sus deploys sin necesidad real. El costo es mantener el starter kit sincronizado entre repos, que el "reusable workflow" de CI ayuda a bajar.
- **No extraer el starter kit todavía.** Con un solo sitio (SerEbro) no hay un segundo caso real contra el cual validar qué es "genérico" y qué es específico de boxeo/UFC — extraerlo ahora sería adivinar. Lo haría recién cuando arranque el segundo sitio, comparando los dos para separar bien lo compartido de lo particular.
- **Mantener el hábito que ya funcionó acá:** cada bug real se convierte en un script de `scripts/audit-*.sh`, no solo en una línea de un documento. Es lo que hizo que `make doctor` hoy pase limpio y no dependa de que alguien se acuerde de mirar a mano.

## Cómo pienso comunicar esto de acá en más

Quedó anotado en el sistema de memoria (memoria de tipo `feedback` y `project`) que puedo opinar libremente sobre estos puntos al cierre de una tarea, sin interrumpir con preguntas a mitad de camino — las preguntas quedan reservadas para bloqueos reales que no puedo resolver con una decisión propia razonable.
