# ARCHITECTURE.md — Decisiones de Diseño

## Decisiones Vigentes

Cambios que no son triviales van aquí. Esto guía decisiones futuras.

### 1. Header Transparente en Home (position: absolute)

**Decisión:** Header es `position: absolute` solo en `body.home`, crea overlay sobre hero.

**Por qué:** Efecto visual limpio en hero rotativo. El header no ocupa espacio en documento.

**Implicación:** Hero-home necesita `padding-top` para compensar altura del header absoluto.

**Valores actuales:**
- Desktop: `180px`
- Tablet: `140px`
- Mobile: `210px`

**Riesgo:** Cambios en altura del header rompen estos valores. Ajustar si header crece o achica.

---

### 2. Responsive Breakpoints

**Decisión:** Mobile-first (base para desktop, reducir en media queries).

**Breakpoints:**
- `≤600px` — Mobile (375px-600px)
- `601-1023px` — Tablet (768px óptimo)
- `≥1024px` — Desktop

**Por qué:** Coincide con viewport common; mobile-first es patrón estándar.

**Implicación:** Cambios CSS deben estar en media queries correctas.

---

### 3. Grid de Cards

**Decisión:** 
- Home: 4 col (desktop), 2 col (tablet+mobile)
- Secciones: 3 col (desktop), 2 col (tablet), 1 col (mobile)

**Por qué:** Consistencia + predictibilidad. NO usar `repeat(auto-fill)` (impredecible en mobile).

**Implicación:** CSS selector-specific, no generic. Mantener `.cartas-grid-home` y `.cartas-grid` separados.

---

### 4. Color Palette

**Variables CSS (en `:root`):**
- `--bg-body: #F0E3CF` — Fondo principal (beige)
- `--accent: #d20a0a` — Rojo deportivo
- `--color-dorado: #c9a84c` — Detalles/dorado
- `--color-header: #1e1e1e` — Header overlay
- `--text-main: #1a1814` — Texto oscuro

**Por qué:** Refleja identidad. Todos los colores usan variables.

**Implicación:** Cambios de paleta = actualizar `:root` + revisar dark-mode.css

---

### 5. Dark Mode

**Decisión:** CSS override en `dark-mode.css`. Disabled por defecto, activado por toggle.

**Por qué:** Separa concerns. Dark mode no rompe light mode.

**Implicación:** Dark-mode.css debe reflejar cambios de responsive en style.css

---

### 6. Images

**Decisión:** Solo `.webp` en versionado. Locales pueden tener `.jpg`.

**Por qué:** Eficiencia. `.gitignore` ignora `.jpg`.

**Implicación:** Script `scripts/cleanup-images.sh` elimina .jpg locales. No commitear .jpg.

---

## Cómo Usar Este Archivo

- **Antes de cambiar arquitectura:** Revisá si está aquí
- **Cuando descubras un patrón importante:** Documentalo aquí
- **No agregues detalles técnicos:** Van en comentarios en el código, no aquí

---

## Cambios Futuros Potenciales

(Espacio para decisiones nuevas)
