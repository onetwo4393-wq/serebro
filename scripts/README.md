# Scripts de auditoría — qué son y por qué existen

Estos cuatro scripts nacieron directamente de bugs reales encontrados y arreglados en este repo (ver `AUDITORIA_SONNET.md` en la raíz) y de la reflexión de proceso en `WORKSPACE_MEJORAS.md` (puntos 1-2: falta de linter de cascada CSS y de CI). No son genéricos — cada uno detecta el patrón exacto de un bug que ya pasó acá.

## `audit-css.sh`

Detecta los dos patrones de cascada que causaron bugs visuales en producción:

- **Selector duplicado fuera de `@media`** — el caso de `.carta-rating`, que estaba definido dos veces separadas por 277 líneas y se fusionaba silenciosamente en la cascada. Esto fue la causa raíz de por qué el bug del badge de Canelo (amarillo vs dorado) tardó varios turnos en diagnosticarse.
- **Selector dentro de un `@media` Y de nuevo sin condición más abajo** — el caso de `.cartas-grid-home`, que mostraba 4 columnas en tablet en vez de 2 porque una regla incondicional agregada al final del archivo pisaba la regla responsive definida antes.
- Como bonus, también lista clases CSS sin ninguna referencia en `templates/` ni `content/` (CSS muerto — encontró el typo `.footer` vs `footer` en su momento) y la densidad de `!important` por archivo (informativo).

## `audit-darkmode.sh`

Detecta el patrón que causó específicamente el bug de color de Canelo:

- **Variables de `:root` de paleta/color que existen en `style.css` pero no en `dark-mode.css`** (o viceversa) — asimetrías silenciosas entre light y dark mode. Filtrado a variables de color/paleta únicamente (no tipografía ni layout), porque `dark-mode.css` declara explícitamente en su propio encabezado que solo toca eso.
- **Colores hex hardcodeados en `style=""` inline** en vez de `var(--...)` — un color así nunca puede adaptarse a dark mode sin importar qué diga `dark-mode.css`. Encontró el caso ya arreglado de `sobre-jorge.html`, y de paso encontró **3 casos nuevos que la auditoría manual no había marcado como bug** (`#fff` hardcodeado en `contacto.html`, `404.html`, `evento.html` — ver nota abajo).
- Selectores en `dark-mode.css` que no existen en `style.css` ni en ningún template — overrides muertos (encontró `.hero-seccion` en su momento, ya limpiado).

## `audit-build.sh`

Smoke test post-build: "el build no tira error" no es lo mismo que "el sitio sirve lo que debería". Corre `zola build` y después confirma que las rutas clave (home, ufc, boxeo, mma, protagonistas, sobre-jorge, contacto) existen y contienen un string esperado, más que los assets CSS críticos se compilaron. `eventos/` y `exclusivas/` quedan afuera de la lista a propósito — tienen `render = false` en su `_index.md`, así que no generan `index.html` por diseño.

## `audit-frontmatter.sh`

Detecta los dos patrones de bug de *datos* en `content/protagonistas/*.md` (no CSS):

- **`rating` declarado sin comillas** — el caso de Canelo (`rating = 98` en vez de `rating = "98"`, único distinto al resto).
- **`nacionalidad` que no matchea ningún país conocido del macro `carta_peleador`** ni contiene "Estados Unidos" — el bug de Paddy Pimblett/Yoel Romero (caían silenciosamente en la bandera de EE.UU.), ya arreglado para esos dos. La lista de países conocidos se lee directamente de `macros.html`, no está hardcodeada en el script, para que se mantenga sola si se agrega un país nuevo al template.
- Al escribir este script encontró un caso real que nadie había notado: `teofimo-lopez.md` tiene `nacionalidad = "Honduras / USA"` (usa "USA", no "Estados Unidos"), así que cae al fallback silencioso igual que Paddy/Yoel caían antes de arreglarse. Queda como warning (no falla `make doctor`) porque puede ser un fallback intencional — requiere criterio humano, no es tan claro como los otros casos.

## `make doctor`

Corre los cuatro audits de punta a punta, **sin cortar en el primer fallo** (a diferencia del comportamiento default de `make`), para dar el diagnóstico completo de una sola corrida — como un `flutter doctor` o `brew doctor`. Sale con código distinto de cero si al menos uno falló.

```bash
make doctor            # los 4 audits juntos
make audit-css         # solo cascada CSS
make audit-darkmode    # solo sincronización light/dark
make audit-build       # solo build + smoke test
make audit-frontmatter # solo tipos/nacionalidad en content/protagonistas
make build              # zola build
make serve               # zola serve --interface 0.0.0.0 --port 1111
```

## ⚠️ Estado actual: `make doctor` NO pasa limpio hoy

`audit-darkmode.sh` encuentra 3 hallazgos reales que no estaban en `AUDITORIA_SONNET.md` ni se arreglaron en la sesión de fixes: `color: #fff` hardcodeado inline en `contacto.html:25`, `404.html:7` y `evento.html:20`, en vez de `var(--color-blanco)`.

En su momento los descarté como "no es un bug, blanco sobre fondo de acento funciona igual en ambos modos" — y visualmente es cierto. Pero el propio script los marca porque es exactamente la misma categoría de problema que sí se arregló en `sobre-jorge.html` (color hardcodeado con una variable equivalente ya disponible), solo que sin consecuencia visible todavía. Los dejé sin tocar a propósito — decidir si vale la pena arreglarlos (o silenciarlos explícitamente en el script) queda para otra sesión, no para esta.

## Nota sobre la parte que quedó pendiente

Esta sesión también pedía instalar herramientas permanentemente (ripgrep, fd, tree, bat, jq, Node+npm, Playwright) editando un `Containerfile` en `/workspace/../Containerfile`. Ese archivo no existe en ningún lado de este filesystem — no es parte de este repo ni de este entorno sandboxed. Se decidió, junto con el usuario, dejar esa parte para otra sesión (posiblemente en el entorno real donde ese Containerfile sí vive) y avanzar solo con `scripts/` + `Makefile`, que sí son parte del repo.
