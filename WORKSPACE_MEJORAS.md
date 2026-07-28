# WORKSPACE_MEJORAS.md — Reflexión de Ingeniería

**Contexto:** este documento resume lo que aprendí trabajando varias sesiones seguidas en este repo — diagnóstico de un bug visual, una auditoría completa y el arreglo de los 10 hallazgos, en ese orden. No es una lista de deseos abstracta: cada punto de acá salió de un momento concreto donde perdí tiempo, me equivoqué, o tuve que reconstruir a mano algo que una herramienta debería darme gratis.

No incluye código todavía — es diagnóstico de proceso, para decidir qué vale la pena construir.

---

## Priorización por impacto

| # | Problema | Impacto real que tuvo esta sesión | Qué lo resuelve |
|---|---|---|---|
| 1 | Sin forma de ver el resultado visual de un cambio CSS | Causa raíz de la mayor parte del ida y vuelta: varias rondas de "sigue siendo amarillo" que un screenshot hubiera resuelto en el primer intento | Screenshot automatizado (headless browser) en 2 temas × 3 viewports |
| 2 | Sin herramienta para resolver la cascada CSS de un selector | Encontré los 3 bugs de cascada (`.cartas-grid-home`, `.footer`, `.carta-rating` duplicado) leyendo 714 líneas a mano, más de una vez | Linter de CSS (Stylelint) + script que resuelve "qué gana" para un selector dado |
| 3 | Sin documentación de qué herramientas de shell existen en este entorno | `pgrep`/`pkill` no existen acá; `curl` a localhost lo bloquea un proxy — descubrí ambas cosas por prueba y error, en medio de una tarea | Un archivo `ENVIRONMENT.md` con el inventario real |
| 4 | Sin CI que corra build/lint antes de mergear | Los 3 bugs de cascada estaban en `main`, deployados en producción, nadie los había visto | CI mínimo: `zola build` + linter en cada push |
| 5 | Sin validación de frontmatter | El bug de Canelo (`rating` como entero) y el de Paddy/Yoel (nacionalidad sin clase de bandera) son ambos "faltó una validación de datos", no "faltó lógica" | Script de esquema para `content/**/*.md` |
| 6 | Sin single-source-of-truth para componentes repetidos | La tarjeta de peleador vivía duplicada en 2 templates; encontré `.carta-rating` duplicado en CSS. Ya arreglé ambos, pero nada impide que vuelva a pasar | Convención + lint que detecte bloques HTML/CSS casi idénticos |
| 7 | `settings.local.json` sin lista curada de permisos | Cada comando nuevo (grep con flags distintos, `awk`, `diff`, `for`) disparaba una confirmación, incluso siendo de solo lectura | Allowlist mantenida junto con el repo (ya lo empezamos a resolver en esta sesión) |

Los puntos 1 y 2 concentran, en mi estimación, más del 70% del tiempo perdido en esta sesión. Si tuviera que elegir uno solo para resolver antes de seguir trabajando acá, sería el 1.

---

## 1. Herramientas que me faltaron

**Verificación visual.** `CLAUDE.md` es explícito: *"Cambios CSS SIEMPRE verificar EN NAVEGADOR antes de reportar"*. No tengo forma de cumplir esa regla — no hay navegador, no hay captura de pantalla, no hay forma de "ver" el resultado. Lo único que puedo hacer es leer el CSS compilado y razonar sobre la cascada en mi cabeza, lo cual es exactamente el tipo de tarea en la que un humano (y yo) nos equivocamos: la cascada CSS tiene reglas que interactúan de formas no obvias, y esta sesión lo probó — tardé varias rondas en encontrar que el problema real era el `background` sólido del badge, no el tono de color, porque nunca pude *ver* que el cuadrado se veía como un bloque sólido en vez de una caja con acento.

**Un navegador headless (Playwright/Puppeteer) con capacidad de screenshot** hubiera cortado esa cadena de rondas a la mitad o menos.

**Resolución de cascada CSS.** No tengo ninguna herramienta que me diga "para el selector `.carta-rating-num`, con estos dos archivos cargados en este orden, ¿qué regla gana y con qué valor final?". Tuve que simular esto a mano, leyendo los 714 + 150 líneas completos más de una vez, y me equivoqué al menos una vez en el proceso: corregí el `!important` cuando el problema real era otra propiedad.

**Un servidor local persistente y confiable.** `pgrep`/`pkill` no existen en este entorno — lo descubrí a mitad de una tarea, cuando intenté reiniciar `zola serve` y el comando falló silenciosamente. Tuve que iterar para encontrar una forma alternativa de manejar el proceso en background.

**Verificación HTTP del servidor.** Cuando intenté `curl http://localhost:1111`, un proxy (`tinyproxy`) devolvió `403 Filtered`. No es un problema del proyecto, es del entorno — pero me costó una llamada entera descubrirlo, y significa que ni siquiera pude confirmar que el servidor respondía, mucho menos ver el HTML renderizado.

---

## 2. Scripts que hubieran acelerado el trabajo

- **Screenshot en batch:** un script que levante `zola serve`, tome capturas del home + una sección + una tarjeta de protagonista, en light y dark mode, en 375px/768px/1024px, y las deje en una carpeta para comparar antes/después de un cambio CSS. Esto es, con diferencia, lo que más tiempo me hubiera ahorrado.
- **Buscador de CSS muerto real:** hice esto a mano con un loop de bash y grep heurístico — funcionó, pero tuvo falsos positivos (matcheó `.webp` como si fuera una clase CSS porque mi regex no distinguía una URL de un selector). Una herramienta tipo PurgeCSS, corrida contra los templates compilados, lo hace bien y rápido.
- **Detector de selectores duplicados/casi-duplicados:** algo que recorra `style.css` y avise "`.carta-rating` está definido en la línea 365 Y en la línea 642" antes de que alguien tenga que descubrirlo depurando un bug de color en producción.
- **Diff de HTML compilado entre dos commits o dos templates:** lo hice con Python inline, ad hoc, cada vez que necesitaba comparar la tarjeta de Justin (home) contra la misma tarjeta en `/ufc/`, o el HTML antes/después de extraer el macro. Un script reusable (`scripts/diff-rendered.sh <selector> <ref1> <ref2>`) hubiera evitado reescribir ese one-liner cada vez.
- **Validador de frontmatter:** un script que recorra `content/**/*.md` y chequee tipos consistentes (¿`rating` es siempre string?), campos requeridos según la sección, y que cada `nacionalidad` tenga una clase de bandera correspondiente en el template — hubiera encontrado 2 de los 10 bugs de la auditoría sin que yo tuviera que leer 56 archivos a mano.
- **Smoke test post-build:** `zola build` + levantar el server + pegarle a un puñado de rutas conocidas (`/`, `/ufc/`, `/boxeo/`, una nota, un protagonista) verificando que devuelvan 200 y contengan ciertos fragmentos esperados. Ahora mismo "verificar que el build funciona" es sinónimo de "no tira error", no de "el sitio realmente sirve lo que debería".

---

## 3. Documentación que me hubiera evitado errores

**Un inventario del entorno.** No sabía que `pgrep`/`pkill` faltaban ni que `curl` a localhost estaba proxeado hasta que fallaron en medio de una tarea. Un `ENVIRONMENT.md` corto ("estos binarios existen, estos no, así se reinicia el server acá, así se verifica que responde") ahorra ese descubrimiento por prueba y error en la primera sesión de cualquiera que trabaje acá — humano o agente.

**La advertencia de cascada de `ARCHITECTURE.md` necesita ser accionable, no solo narrativa.** La sección 2.1 documenta el patrón exacto que después encontré en `.cartas-grid-home` — pero está escrita como anécdota de un incidente pasado en un selector específico, no como una regla que yo pudiera aplicar sistemáticamente para buscar *otras* instancias del mismo patrón en el archivo. Terminé encontrando el segundo caso por auditoría manual completa, no porque el documento me hubiera dado una forma de buscarlo. Una checklist tipo "antes de agregar una regla sin media query, `grep` el selector para confirmar que no exista ya dentro de un `@media`" hubiera sido más útil que la narración del incidente.

**Nada advertía que `.carta-rating` estaba duplicado.** Cuando llegué a esa parte del CSS por primera vez, no había ningún comentario tipo "cuidado: hay otra definición de esto en la línea X" — un comentario así habría cambiado por completo cuánto tiempo me tomó diagnosticar el bug de Canelo en los primeros turnos de esta sesión.

**Sin registro de qué diferencias entre `style.css` y `dark-mode.css` son intencionales vs. accidentales.** Cuando encontré que `--color-dorado-brillante` era amarillo en dark mode y dorado en light mode, no tenía forma de saber si eso era un diseño deliberado ("dark mode usa un dorado más saturado a propósito") o simple deriva accidental. Un comentario o un `CHANGELOG.md` con decisiones de paleta hubiera resuelto la ambigüedad en segundos en vez de que tuviera que asumir (correctamente, pero sin certeza) que era un error.

---

## 4. Comandos que repetí demasiado

- `zola build 2>&1 | tail -5` — lo corrí después de literalmente cada edición, más de 15 veces en la sesión de fixes, solo para confirmar que no rompí la sintaxis. Necesario, pero mecánico — es exactamente lo que un hook de pre-commit debería hacer sin que yo tenga que acordarme.
- `grep -n "patrón" archivo` para ubicar el número de línea exacto antes de cada `Edit` — decenas de veces. El propio flujo de trabajo (leer → confirmar línea → editar) es repetitivo porque no hay una forma de decir "reemplazá la regla del selector X" sin primero encontrarla a mano.
- `git add <archivo> && git commit -m "$(cat <<'EOF' ... EOF)"` — el patrón heredoc para mensajes largos, 10 veces seguidas en la sesión de fixes. Funciona bien, pero es ceremonia repetida que un script `scripts/commit-fix.sh "<mensaje>"` podría envolver.
- Intentos fallidos de `pgrep`/`pkill` — no exactamente "repetido", pero perdí llamadas completas reaccionando a un error de entorno que un `ENVIRONMENT.md` hubiera prevenido de entrada.
- Comandos Python inline (`python3 -c "..."`) para extraer o diffear fragmentos de HTML — los reescribí desde cero cada vez que los necesité en vez de tener un script reusable.

---

## 5. Archivos que consulté constantemente

- **`static/assets/css/style.css`** (714+ líneas) — lo leí completo o casi completo al menos 4 veces en total a lo largo de la sesión, porque cada tarea nueva necesitaba el archivo entero en contexto para razonar sobre la cascada.
- **`static/assets/css/dark-mode.css`** — mismo patrón, leído completo múltiples veces.
- **`templates/index.html` y `templates/seccion.html`** — los comparé lado a lado repetidamente antes de confirmar que el bloque de tarjeta era duplicado carácter por carácter.
- **`ARCHITECTURE.md` y `CLAUDE.md`** — vueltos a consultar cada vez que necesitaba confirmar una decisión de diseño documentada (breakpoints, paleta, el patrón de cascada) antes de tocar algo relacionado.
- **`zola.toml`** — para entender qué protagonistas aparecen en el home y qué exclusiones aplican por sección, cada vez que necesitaba predecir qué tarjeta iba a aparecer dónde.
- **Frontmatter de `content/protagonistas/*.md`** — grepeado repetidamente para cruzar `nacionalidad`, `disciplina` y `rating` contra la lógica de los templates.

---

## 6. Información que costó encontrar

- **El valor final, post-cascada, de una propiedad CSS para un elemento dado.** Esto fue, de lejos, lo más costoso de toda la sesión — no existe ninguna herramienta que me dé esta respuesta directamente; tuve que reconstruirla leyendo el archivo completo y simulando el algoritmo de cascada mentalmente, y me equivoqué al menos una vez en el camino.
- **Si una clase CSS realmente se usa en algún lado.** Mi primer intento (grep heurístico) tuvo falsos positivos. Tuve que verificar cada resultado a mano antes de confiar en la lista.
- **Qué breakpoint aplica a qué ancho de viewport, considerando las 3 (ahora 4) definiciones de `.cartas-grid-home` dispersas en el archivo.** Reconstruir esto requería ensamblar información de 4 ubicaciones distintas del mismo archivo.
- **Qué nacionalidades tenían clase de bandera y cuáles no.** Tuve que cruzar manualmente cada valor de `nacionalidad` en el contenido contra la cadena `if/elif` de los templates — no había ningún lugar centralizado que listara "estos son los países soportados".
- **Qué ruta URL renderiza qué template.** No hay un mapa explícito; lo infería de `zola.toml`, de los nombres de carpeta en `content/`, y de prueba y error con `zola build`.

---

## 7. Qué automatizaría (si pudiera escribir código hoy)

En orden de lo que haría primero:

1. **Screenshot automatizado post-cambio CSS**, en los 2 modos × 3 viewports que `ARCHITECTURE.md` ya define como los oficiales del proyecto. Esto convierte la regla "SIEMPRE verificar EN NAVEGADOR" de una instrucción que no puedo cumplir en una que sí puedo.
2. **Lint de CSS en pre-commit** (Stylelint con reglas de no-duplicados, o un script propio) — hubiera atajado 3 de los 10 bugs de la auditoría antes de que llegaran a `main`.
3. **CI mínimo en cada push:** `zola build` (falla si hay error de sintaxis Tera/CSS) + el lint del punto 2. Hoy no hay nada entre "yo edito un archivo" y "Netlify lo deploya a producción".
4. **Validador de esquema de frontmatter**, corrido también en CI, para los tipos de dato y campos requeridos por tipo de contenido.
5. **`ENVIRONMENT.md`** documentando qué herramientas de shell existen en este sandbox específico, para que la próxima sesión no pierda tiempo redescubriendo que `pgrep` no está.
6. **Un script de smoke test** que levante el sitio y confirme que las rutas clave responden con el contenido esperado, corrido como último paso antes de considerar una tarea "terminada".

No incluyo código en este documento a propósito — es el punto de partida para decidir, con vos, cuáles de estos vale la pena construir primero.
