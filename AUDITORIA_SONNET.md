# Auditoría Técnica — SerEbro En Los Deportes

**Fecha:** 2026-07-26
**Alcance:** CSS (`style.css`, `dark-mode.css`), templates (`templates/*.html`), contenido (`content/**/*.md`), configuración (`zola.toml`).
**Metodología:** Lectura completa de ambos archivos CSS (714 + 150 líneas), los 12 templates, grep sistemático de selectores contra su uso real en templates/contenido, y verificación manual de cada hallazgo antes de incluirlo. No se tocó ningún archivo — solo lectura y análisis.

Todos los hallazgos de este documento fueron verificados leyendo el código fuente real, no inferidos. Donde digo "confirmado", significa que crucé la definición CSS/HTML contra su uso (o falta de uso) real.

---

## 1. ESTRUCTURA CSS

### 1.1 🔴 Bug activo: `.cartas-grid-home` rompe el layout de tablet (cascada silenciosa, en producción ahora mismo)

Este es el hallazgo más importante del documento. Es exactamente el patrón que `ARCHITECTURE.md` sección 2.1 documenta como peligroso ("el que viene después en el archivo gana") — pero está ocurriendo en vivo, sin detectar, en una regla distinta a la que motivó esa documentación.

**Las 4 definiciones de `.cartas-grid-home` en `style.css`, en orden de aparición:**

```
línea 402:  @media (768-601px) tablet   → repeat(2, 1fr)              [sin !important]
línea 453:  @media (≤600px) mobile      → repeat(2, 1fr) !important
línea 631:  regla base, SIN media query → repeat(4, 1fr)              [sin !important]
línea 707:  @media (≥1024px) desktop    → repeat(4, 1fr)              [sin !important]
```

**El problema:** la regla de la línea 631 no tiene media query — se aplica siempre, incondicionalmente. En viewport tablet (ej. 768px, el que `ARCHITECTURE.md` llama "óptimo"), la regla 402 (2 columnas) y la regla 631 (4 columnas) tienen **exactamente la misma especificidad** (una sola clase). Gana la que aparece después en el archivo: la 631. Como la 631 no tiene `!important`, nada la detiene.

**Resultado real:** en tablet, la grilla "Los Protagonistas" del home muestra **4 columnas**, no las 2 que documenta `ARCHITECTURE.md` sección 3 ("Home: 4 col (desktop), 2 col (tablet+mobile)"). En mobile no pasa porque la línea 453 sí tiene `!important` y ese sí gana pase lo que pase.

Confirmé que `.cartas-grid` (sin `-home`, usado en las secciones normales) **no tiene este problema** — se define una sola vez, antes de sus media queries, y nunca se vuelve a tocar.

**Por qué pasó:** alguien agregó la regla de 4 columnas para el home (línea 631) en un bloque nuevo al final del archivo, sin notar que ya existían reglas responsive para la misma clase 200+ líneas antes.

### 1.2 🔴 Bug activo: el footer nunca recibe su padding reducido en mobile

Línea 450, dentro del media query mobile:
```css
.footer { padding: 25px 15px; margin-top: 50px; }
```

Pero el `<footer>` en `base.html:59` **no tiene ninguna clase** — es solo la etiqueta `<footer>`. La regla base del footer (línea 229) sí usa el selector de elemento correcto (`footer { ... }`), pero esta regla mobile usa `.footer` (selector de clase) por error. Nunca matchea nada. El footer se queda con su padding de desktop (`40px 20px`) y `margin-top: 80px` en todos los viewports, incluido mobile — donde ese espaciado es proporcionalmente excesivo.

Es un typo de un solo carácter (`.footer` vs `footer`) con impacto real y silencioso.

### 1.3 Regla duplicada/parcialmente muerta: dos bloques `.carta-rating`

Ya lo tocamos indirectamente en esta sesión, pero documentando la causa raíz completa: hay **dos definiciones separadas** de `.carta-rating` en `style.css`:

```
línea 365: position, top, right, font-family, font-size, font-weight,
           width: 52px, height: 52px, display: flex, align-items, justify-content,
           border-radius: 4px, z-index: 5, color: #1a1814, background: rgba(201,168,76,0.9),
           box-shadow

línea 642: position, top, right, background: rgba(0,0,0,0.75),
           border: 1px solid rgba(201,168,76,0.5), padding: 4px 8px,
           min-width: 46px, text-align: center, border-radius: 2px,
           z-index: 5, transition
```

No es que una esté "muerta" — **se fusionan silenciosamente**. Para las propiedades que ambas definen (`background`, `border-radius`, `position/top/right`, `z-index`), gana la 642 por venir después. Para las que solo define la 365 (`width`, `height`, `display: flex`, `font-*`, `color: #1a1814`, `box-shadow`), esas **sí se aplican** aunque estén 277 líneas antes de la regla "activa". El resultado visual final es una mezcla de ambas reglas que ningún desarrollador que lea solo una de las dos podría predecir. Esto es, con altísima probabilidad, la causa original de por qué el bug de Canelo fue tan difícil de rastrear en los turnos anteriores de esta conversación: dos fuentes de verdad para el mismo selector.

**Recomendación:** fusionar en una sola regla y eliminar la de línea 365, o renombrar una de las dos si en verdad tienen propósitos distintos.

### 1.4 CSS muerto confirmado (0 referencias en templates/contenido)

Verificado por grep cruzado, cada uno confirmado manualmente (no solo por heurística):

- `.sidebar`, `.sidebar-titulo` (línea 276-277) — el sidebar real en `protagonista.html` usa la clase `protagonista-sidebar`, que no tiene reglas propias (depende solo del grid de `.protagonista-layout`). Este bloque es un remanente de un diseño anterior.
- `.lista-stories`, `.item-story`, `.story-numero`, `.story-titulo` (líneas 278-284) — sistema de "lista numerada de historias" que ya no se usa en ningún template. El sidebar actual usa `.entrevista-card` en su lugar.
- `.hero-seccion`, `.hero-seccion-titulo`, `.hero-seccion-desc` (líneas 265-270) — no aparecen en ningún template actual. `evento.html` y `seccion.html` no las usan.
- `.layout-top` (línea 273) — sin uso.

Esto es aproximadamente **20 líneas de CSS** manteniendo un diseño de sidebar/hero que ya fue reemplazado, sin que nadie las haya limpiado.

### 1.5 `!important`: conteo y distribución

- `style.css`: **42** ocurrencias
- `dark-mode.css`: **7** ocurrencias (bajó de las que había antes en esta sesión, pero sigue habiendo)

La gran mayoría de los `!important` en `style.css` están concentrados en el bloque mobile (líneas 452-524: header stack vertical, nav, logo, theme-toggle) — ahí se justifican porque están peleando contra reglas base de layout horizontal con la misma especificidad, y es un patrón consciente y contenido a un solo media query.

El único `!important` verdaderamente "innecesario" que identifiqué es el de la línea 453 (`.cartas-grid-home` mobile) — pero irónicamente **ese es el único que está salvando** al mobile del mismo bug que rompe tablet (ver 1.1). No lo tocaría sin arreglar antes la causa raíz.

En `dark-mode.css`, los 7 `!important` restantes están en dos grupos: los que pisan atributos de presentación SVG (`.carta-rating-hex polygon/text`, líneas 108-110 — ahí **sí son necesarios**, porque un atributo de presentación SVG sin `!important` puede perder contra ciertas reglas) y los de `.carta-rating-ovr`/`.carta-rating-num` (líneas 98-99) que ya no son estrictamente necesarios tras el fix de esta sesión (el problema real era el `background`, no la especificidad) pero no hacen daño dejarlos.

### 1.6 Variables CSS: buena cobertura, con una fuga

El sistema de variables (`:root` en ambos archivos) está bien pensado — `dark-mode.css` redefine las mismas variables que `style.css` define, así que cualquier código que use `var(--algo)` se adapta automáticamente sin necesitar `!important` ni duplicar reglas. Es el patrón correcto.

La fuga: `sobre-jorge.html:14` tiene `style="color: #c9a84c; ..."` hardcodeado en vez de `var(--color-dorado)`. Hoy no se nota porque `#c9a84c` es justo el valor de `--color-dorado` en ambos modos — pero si alguna vez se decide dar un dorado distinto para dark mode, este punto no se va a enterar y quedará desincronizado. Es el único lugar de todo el codebase con un color de marca hardcodeado en vez de variable.

### 1.7 Nomenclatura de archivo con typo (cosmético, no bug)

`static/assets/img/hero/estructura_audo.webp` — el nombre del archivo tiene un typo ("audo" en vez de "auto"). No es un bug porque el CSS lo referencia con el mismo nombre (typo incluido) y el archivo existe, así que la imagen carga bien. Es deuda técnica menor: cualquiera que edite ese CSS sin mirar el nombre real del archivo asumirá que está mal escrito y "lo va a arreglar", rompiendo la referencia.

---

## 2. ESTRUCTURA HTML / TEMPLATES

### 2.1 Duplicación exacta: el bloque de tarjeta de peleador vive en dos templates

`templates/index.html` (líneas 26-55) y `templates/seccion.html` (líneas 23-52) contienen **el mismo bloque de ~30 líneas** que renderiza una tarjeta de peleador (acento, borde, badge hex/cuadrado según disciplina, foto, overlay, país, nombre, stats). La única diferencia real es el loop que decide qué protagonistas mostrar — el marcado de la tarjeta en sí es idéntico carácter por carácter.

Esto tiene una consecuencia concreta que ya viviste en esta sesión: cualquier cambio al marcado del badge de rating (el hexágono SVG o el cuadrado) hay que hacerlo **en dos archivos**, y si se olvida uno, aparecen inconsistencias entre "cómo se ve en el home" y "cómo se ve en la sección" — el mismo tipo de bug de consistencia visual que motivó toda esta conversación, pero a nivel de marcado en vez de CSS.

**Recomendación concreta:** `macros.html` ya existe y hoy solo tiene un macro (`fecha_es`). Es el lugar natural para agregar un macro `carta_peleador(prot, clase_pais)` que ambos templates importen. Reduciría ~30 líneas duplicadas a una sola fuente de verdad.

### 2.2 Fallback de color de país: dos peleadores reciben banderas equivocadas

En `index.html:19` y `seccion.html:16`, la clase de color de país arranca en `carta-us` por defecto y solo cambia si la nacionalidad contiene "Georgia", "México", "Irlanda", "Rusia" o "Brasil":

```jinja
{% set clase_pais = "carta-us" %}
{% if prot.extra.nacionalidad is containing("Georgia") %}...
{% elif ... México ... Irlanda ... Rusia ... Brasil %}...
{% endif %}
```

Crucé esto contra las nacionalidades reales en `content/protagonistas/*.md`:

- **Paddy Pimblett** — `nacionalidad = "Inglaterra"` → no matchea ninguna condición → cae en `carta-us` → recibe la barra de acento con los colores de la bandera de Estados Unidos (rojo/blanco/azul marino, `#b22234, #ffffff, #3c3b6e`).
- **Yoel Romero** — `nacionalidad = "Cuba"` → mismo problema → también recibe colores de bandera de EE.UU.

Esto es alcanzable en producción: Paddy Pimblett tiene `disciplina = "ufc"` y no está en la lista de exclusión del home, así que puede aparecer en `/ufc/` mostrando la bandera equivocada.

**Nota:** "Irlanda" está soportado como caso especial pero "Inglaterra" no, pese a que ambos son del Reino Unido — sugiere que el diseño original solo contempló los países de los protagonistas que existían en ese momento, sin previsión para los agregados después.

### 2.3 Inconsistencia de tipo en frontmatter: `rating`

`content/protagonistas/canelo-alvarez.md:13` tiene `rating = 98` (entero, sin comillas). **Todos los demás** protagonistas con rating (Justin Gaethje, Max Holloway, Islam Makhachev, Topuria, etc.) tienen `rating = "95"` (string, con comillas). Hoy no rompe nada porque Tera renderiza ambos igual como texto — pero es una inconsistencia de datos que, si algún día se agrega lógica que compare o sume ratings numéricamente, va a fallar solo para Canelo de forma no obvia.

### 2.4 Estilos inline: uso extendido, pero consistente en su patrón

Conteo de bloques `style="..."` por template:

| Template | Bloques inline |
|---|---|
| sobre-jorge.html | 14 |
| contacto.html | 13 |
| evento.html | 9 |
| protagonista.html | 6 |
| 404.html | 5 |
| page.html | 3 |
| protagonistas.html | 2 |
| coming_soon.html | 1 |
| seccion.html | 1 |

Es bastante estilo inline para un sitio que también mantiene dos hojas de estilo externas. La buena noticia, verificada: casi todos usan `var(--variable)` en vez de colores hardcodeados, así que sí se adaptan correctamente a dark mode (las variables CSS se resuelven en tiempo de render, no de parseo, así que un `style="color: var(--accent)"` inline cambia de color igual que si estuviera en una hoja externa). La única excepción hardcodeada es la de `sobre-jorge.html` mencionada en 1.6.

El riesgo no es que esté roto hoy — es que cada nuevo estilo inline que alguien agregue sin usar `var()` va a crear una inconsistencia de dark mode silenciosa, exactamente como la de esta sesión pero en un lugar distinto del código, y sin la ventaja de que `dark-mode.css` la centralice.

### 2.5 Frontmatter: `slug` no se declara en ningún archivo de contenido

`README.md` dice literalmente "Frontmatter obligatorio: `title`, `date`, `slug`". Revisé los ~56 archivos de contenido y **ninguno** declara `slug` explícitamente — Zola lo infiere del nombre de archivo, así que no es un bug funcional, pero la documentación no refleja la práctica real del repo. O se actualiza el README, o se empieza a declarar `slug` como dice la documentación.

### 2.6 Dark mode no persiste entre páginas

Confirmé que no hay `localStorage`, `sessionStorage` ni cookies en ningún template — el toggle de `base.html:50` solo alterna el atributo `disabled` del `<link>` en memoria, para esa carga de página. Como es un sitio multi-página (no SPA), cada navegación a una nota, sección o protagonista **resetea a light mode**, sin importar que el usuario lo haya activado en la página anterior.

Esto no es un bug de CSS — es una decisión de arquitectura (o falta de una) que vale la pena que el usuario decida conscientemente: ¿vale la pena agregar 5 líneas de JS con `localStorage` para persistir la preferencia? Hoy cualquier usuario que prefiera dark mode tiene que reactivarlo en cada página que visita.

---

## 3. ARQUITECTURA GENERAL

### 3.1 Lo que está bien (para no perder de vista en medio de la lista de problemas)

- El sistema de variables CSS compartidas entre `style.css` y `dark-mode.css` es la decisión correcta — permite que la mayoría del sitio se adapte a dark mode sin duplicar reglas.
- `.gitignore` respeta la decisión documentada de solo versionar `.webp` (confirmé que los `.jpg` locales existen en disco pero no están trackeados).
- La separación de contenido (Markdown + frontmatter) de presentación (templates Jinja2) es limpia y sigue el patrón estándar de Zola.
- Los breakpoints responsive son consistentes entre light/dark mode donde corresponde.

### 3.2 Riesgo principal: dos fuentes de verdad para el mismo componente visual

El patrón que se repite en 1.3 (dos `.carta-rating`) y 2.1 (tarjeta duplicada en dos templates) es el mismo riesgo estructural expresado de dos formas distintas: **el mismo componente visual (la tarjeta de peleador y su badge) no tiene una única fuente de verdad**, ni en CSS ni en HTML. Cada vez que hay que tocarlo, hay que acordarse de tocarlo en 2-4 lugares distintos (dos templates × posiblemente dos reglas CSS superpuestas). Esta sesión completa de debugging (Canelo amarillo vs dorado) fue, en el fondo, un síntoma de este riesgo estructural — no un bug aislado.

**Si vas a invertir tiempo en una sola cosa de este documento, sería esta:** crear el macro `carta_peleador` en `macros.html` y limpiar la duplicación de `.carta-rating` en `style.css`. Eso no solo arregla el código actual — hace que la próxima vez que aparezca una inconsistencia visual sea mucho más fácil de rastrear, porque hay un solo lugar donde mirar.

### 3.3 Riesgo secundario: crecimiento de `style.css` como archivo único de 714 líneas

No es un problema hoy, pero la tendencia (reglas nuevas agregadas al final del archivo sin revisar si ya existe algo relacionado más arriba) es exactamente lo que produjo el bug de 1.1. Si el sitio sigue creciendo, vale la pena considerar:
- Reorganizar el archivo por componente en vez de cronológicamente (todo lo de `.carta-*` junto, todo lo de `.nota-*` junto, etc.)
- O, más simple sin cambiar de generador: mover **todas** las media queries al final del archivo de una vez (como sugiere la propia `ARCHITECTURE.md` sección 2.1, opción 2) en vez de tenerlas intercaladas — así cualquier regla nueva sin media query que se agregue al final no puede "colarse" entre una definición base y su responsive override.

### 3.4 Riesgo menor: sin build/lint automatizado

No encontré ningún CI, linter de CSS, ni validación de frontmatter. Los tres bugs de cascada documentados en este archivo (1.1, 1.2, 1.3) son exactamente el tipo de cosa que un linter de CSS (p. ej. Stylelint con la regla `no-duplicate-selectors` o similar) detectaría automáticamente antes de commitear. Dado el tamaño actual del proyecto, probablemente no vale la pena montar CI todavía — pero si el sitio sigue creciendo, es barato de agregar y hubiera evitado varias horas de esta sesión.

---

## Resumen priorizado

| # | Hallazgo | Impacto | Esfuerzo de fix |
|---|---|---|---|
| 1.1 | `.cartas-grid-home` rompe a 4 columnas en tablet | Visual, en producción, viola arquitectura documentada | Bajo — mover regla o agregarle el media query correcto |
| 1.2 | `.footer` (typo) nunca aplica en mobile | Visual, en producción | Trivial — cambiar `.footer` por `footer` |
| 1.3 | Dos `.carta-rating` fusionándose silenciosamente | Mantenibilidad — causa raíz del debugging de esta sesión | Medio — fusionar en una regla |
| 2.2 | Paddy Pimblett / Yoel Romero con bandera de EE.UU. | Visual, en producción, alcanzable en `/ufc/` | Bajo — agregar casos "Inglaterra"/"Cuba" o clase neutra |
| 2.1 | Tarjeta de peleador duplicada en 2 templates | Mantenibilidad — raíz estructural del riesgo #1 | Medio — extraer macro |
| 1.4 | ~20 líneas de CSS muerto (sidebar/stories viejo) | Ninguno hoy, ruido para quien lea el archivo | Trivial — borrar |
| 2.3 | `rating` con tipo inconsistente (Canelo int vs resto string) | Ninguno hoy, riesgo latente | Trivial — poner comillas |
| 2.6 | Dark mode no persiste entre páginas | UX | Bajo — agregar localStorage (decisión de producto, no solo técnica) |
| 1.6 | Un color hardcodeado en vez de variable | Ninguno hoy, riesgo latente | Trivial |
| 2.5 | README dice que `slug` es obligatorio pero nadie lo declara | Documentación desalineada | Trivial — actualizar README o agregar slugs |

No se modificó ningún archivo del proyecto durante esta auditoría.
