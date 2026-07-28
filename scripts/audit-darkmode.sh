#!/usr/bin/env bash
# audit-darkmode.sh — SerEbro
#
# Detecta el patrón de bug que causó el badge de Canelo en amarillo en vez
# de dorado (ver la sesión de debugging completa y AUDITORIA_SONNET.md
# secciones 1.6 y 2.4):
#   1. Variables CSS definidas en :root de style.css que NO están
#      redefinidas en :root de dark-mode.css (o viceversa) — no es
#      necesariamente un error, pero es exactamente el tipo de asimetría
#      silenciosa que hizo tan difícil de rastrear el bug original.
#   2. Colores hex hardcodeados en atributos style="" inline de los
#      templates, en vez de var(--variable) — un color así NUNCA puede
#      adaptarse a dark mode, sin importar qué diga dark-mode.css.
#   3. Selectores en dark-mode.css que no existen en absoluto en
#      style.css ni en ningún template — overrides muertos (el mismo tipo
#      de remanente que encontramos con .hero-seccion).
#
# Uso: ./scripts/audit-darkmode.sh
# Exit code 0 si no encuentra nada, 1 si encuentra al menos un problema.
# Requiere: bash, awk, grep, sed (todos estándar).

set -uo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
CSS_DIR="$BASE/static/assets/css"
STYLE="$CSS_DIR/style.css"
DARK="$CSS_DIR/dark-mode.css"
TEMPLATES_DIR="$BASE/templates"
EXIT_CODE=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

fail() { echo -e "${RED}✗${NC} $1"; EXIT_CODE=1; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
section() { echo -e "\n${BOLD}== $1 ==${NC}"; }

if [ ! -f "$STYLE" ] || [ ! -f "$DARK" ]; then
    fail "no encuentro $STYLE y/o $DARK"
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Extrae los nombres de variable (--algo) definidos dentro del primer
# bloque :root { ... } de un archivo, filtrando solo las que parecen de
# color/paleta (color, bg-, text-, accent, border-). dark-mode.css declara
# explícitamente en su propio encabezado que "solo toca color/paleta — no
# cambia tipografía ni textos", así que --font-*/--max-width no son una
# asimetría real y no vale la pena reportarlas.
extract_root_vars() {
    awk '
        /:root *\{/ { inroot = 1; next }
        inroot && /^}/ { inroot = 0 }
        inroot && match($0, /--[a-zA-Z0-9-]+/) { print substr($0, RSTART, RLENGTH) }
    ' "$1" | grep -E -- '--(color|bg-|text-|accent|border-)' | sort -u
}

extract_root_vars "$STYLE" > "$TMP/style_vars"
extract_root_vars "$DARK"  > "$TMP/dark_vars"

section "1. Variables :root desincronizadas entre style.css y dark-mode.css"

comm -23 "$TMP/style_vars" "$TMP/dark_vars" > "$TMP/only_style"
comm -13 "$TMP/style_vars" "$TMP/dark_vars" > "$TMP/only_dark"

while read -r v; do
    warn "'$v' está en style.css:root pero NO en dark-mode.css:root — si algo la usa con var($v), dark mode heredará el valor de light mode sin darse cuenta"
done < "$TMP/only_style"

while read -r v; do
    warn "'$v' está en dark-mode.css:root pero NO en style.css:root — variable exclusiva de dark mode, confirmar que es intencional"
done < "$TMP/only_dark"

if [ ! -s "$TMP/only_style" ] && [ ! -s "$TMP/only_dark" ]; then
    ok "las variables de :root coinciden entre ambos archivos"
fi

section "2. Colores hex hardcodeados en style=\"\" inline (no se adaptan a dark mode)"

# Nota: process substitution ("< <(...)"), no "| while" — un pipe hacia
# while corre en subshell y ahí "fail" no propaga EXIT_CODE al shell padre.
while IFS=: read -r file line rest; do
    # dentro del atributo style, buscar color:/background:/border-color: seguido de un hex literal
    if echo "$rest" | grep -qE '(color|background|border-color)\s*:\s*#[0-9a-fA-F]{3,6}\b'; then
        hex=$(echo "$rest" | grep -oE '#[0-9a-fA-F]{3,6}' | head -1)
        fail "$(basename "$file"):$line — color hardcodeado $hex en style inline, no usa var(--...) — no se adaptará a dark mode"
    fi
done < <(grep -rnoE 'style="[^"]*"' "$TEMPLATES_DIR")
[ "$EXIT_CODE" -eq 0 ] && ok "sin colores hardcodeados en estilos inline"

section "3. Selectores de dark-mode.css que no existen en style.css ni templates"

grep -oE '^[^{@]*\{' "$DARK" | grep -oE '\.[a-zA-Z][a-zA-Z0-9_-]*' | sort -u | while read -r cls; do
    token="${cls#.}"
    in_style=false
    in_templates=false
    grep -q -- "$token" "$STYLE" 2>/dev/null && in_style=true
    grep -rlq -- "$token" "$TEMPLATES_DIR" 2>/dev/null && in_templates=true
    if [ "$in_style" = false ] && [ "$in_templates" = false ]; then
        warn "dark-mode.css: '$cls' no existe en style.css ni en ningún template — override probablemente muerto"
    fi
done

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    ok "audit-darkmode.sh: sin problemas de sincronización light/dark detectados"
else
    fail "audit-darkmode.sh: revisar los hallazgos de arriba antes de commitear"
fi
exit $EXIT_CODE
