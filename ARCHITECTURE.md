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

**Acoplamiento:** Cambios en altura del header rompen layout del hero SILENCIOSAMENTE (sin error visible).
- Si agregas padding/margin al header, ajusta padding-top del hero
- Si cambias font-size del logo, recalcula
- Si cambias spacing entre nav items, verifica hero no se superpone
- **Verificación:** En DevTools, viewport mobile (375px), confirmar que "EL RADAR" (primer elemento hero) no está bajo header

**Cómo calcular:**
```
Logo height (1.5rem) + Logo subtitle (0.6rem) + padding + gaps + nav
≈ 100-120px. Suma 60-90px de margen de seguridad.
Valores: Desktop 180px, Tablet 140px, Mobile 210px
```

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

### 2.1. ⚠️ CSS Cascade en Media Queries (Patrón Silencioso)

**Problema:** Media query y regla base tienen la MISMA especificidad. El que viene DESPUÉS en el archivo gana.

**Ejemplo real (ocurrió):**
```css
@media (max-width: 600px) {
  .cartas-grid-home { grid-template-columns: repeat(2, 1fr); }  /* Línea 453 */
}

/* ... más CSS ... */

.cartas-grid-home { grid-template-columns: repeat(4, 1fr); }  /* Línea 631 - ESTO GANA */
```

**Síntoma:** Media query no aplica. Cambios responsivos no funcionan. Parece magia.

**Solución:**
1. **!important en media query** (rápida):
```css
@media (max-width: 600px) {
  .cartas-grid-home { grid-template-columns: repeat(2, 1fr) !important; }
}
```

2. **O reestructurar archivo** (limpio): Mover media queries al FINAL del archivo

**Cuándo aplicar:** Cada vez que cambies media queries responsive. Si cambio no funciona, sospecha cascade.

**Verificación:** DevTools (F12) → Selecciona elemento → Verifica "Computed" → ¿Qué regla gana?

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
