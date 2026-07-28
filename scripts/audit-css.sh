#!/usr/bin/env bash
# audit-css.sh — SerEbro
#
# Detecta los patrones de bug de cascada CSS ya encontrados en este repo
# (ver AUDITORIA_SONNET.md secciones 1.1, 1.2, 1.3):
#   1. Un mismo selector de clase definido más de una vez fuera de @media
#      (se fusionan/pisan silenciosamente — causó el bug de .carta-rating).
#   2. Un selector definido dentro de un @media y de nuevo, sin condición,
#      más abajo en el archivo (la regla incondicional gana en ese
#      viewport — causó el bug de .cartas-grid-home en tablet).
#   3. Clases CSS sin ninguna referencia en templates/ ni content/
#      (CSS muerto, o un typo de selector como .footer vs footer que
#      nunca matchea nada).
#   4. Densidad de !important por archivo (informativo).
#
# Uso: ./scripts/audit-css.sh
# Exit code 0 si no encuentra nada, 1 si encuentra al menos un problema.
# Requiere: bash, awk, grep (todos estándar, sin dependencias externas).

set -uo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
CSS_DIR="$BASE/static/assets/css"
TEMPLATES_DIR="$BASE/templates"
CONTENT_DIR="$BASE/content"
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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

section "1-2. Selectores duplicados / regla incondicional después de un @media"

for css in "$CSS_DIR"/*.css; do
    name="$(basename "$css")"

    # Extrae el SELECTOR COMPLETO (todo antes de "{", recortado) de cada
    # línea que abre una regla empezando con ".", junto con si está dentro
    # de un @media (depth>0) o no, y el número de línea. Comparar el
    # selector completo (no solo el primer token) evita falsos positivos
    # como ".carta-ge .carta-acento" vs ".carta-ge .carta-pais" — son
    # selectores distintos aunque compartan el primer token.
    # OJO: "/^[ \t]*@media.*\{[ \t]*$/" (no solo "/@media/") — un comentario
    # que simplemente MENCIONE "@media" en prosa (ej. "ver @media 1024px")
    # no debe contarse como apertura real de bloque; solo cuenta si la
    # línea arranca con @media y termina en "{". Esto pasó de verdad: el
    # comentario del fix de .cartas-grid-home menciona "@media 1024px" y
    # rompía el conteo de profundidad para todo lo que viene después.
    awk -v OFS='|' '
        /^[ \t]*@media.*\{[ \t]*$/ { depth++; next }
        /^}/ && depth > 0 { depth--; next }
        /^\./ && /\{/ {
            line = $0
            sub(/\{.*/, "", line)
            gsub(/^[ \t]+|[ \t]+$/, "", line)
            if (depth > 0) print "media", line, NR
            else print "base", line, NR
        }
    ' "$css" > "$TMP/${name}.selectors"

    # Duplicados fuera de @media (mismo patrón que .carta-rating).
    # Nota: se usa "< <(...)" (process substitution) en vez de "| while" —
    # un pipe hacia while corre el loop en una subshell, y ahí adentro
    # "fail" (que hace EXIT_CODE=1) no se propaga al shell principal.
    awk -F'|' '$1=="base"{print $2}' "$TMP/${name}.selectors" | sort | uniq -d > "$TMP/${name}.dup_base"
    while read -r sel; do
        lines=$(awk -F'|' -v s="$sel" '$1=="base" && $2==s {print $3}' "$TMP/${name}.selectors" | paste -sd, -)
        fail "$name: '$sel' está definido más de una vez fuera de @media (líneas $lines) — se fusionan/pisan silenciosamente, ver 1.3 de AUDITORIA_SONNET.md"
    done < "$TMP/${name}.dup_base"

    # Selector visto dentro de @media Y de nuevo sin condición más abajo
    awk -F'|' '$1=="media"{print $2}' "$TMP/${name}.selectors" | sort -u > "$TMP/${name}.media_sels"
    awk -F'|' '$1=="base"{print $2}' "$TMP/${name}.selectors" | sort -u > "$TMP/${name}.base_sels"
    comm -12 "$TMP/${name}.media_sels" "$TMP/${name}.base_sels" > "$TMP/${name}.media_then_base"
    while read -r sel; do
        media_lines=$(awk -F'|' -v s="$sel" '$1=="media" && $2==s {print $3}' "$TMP/${name}.selectors" | paste -sd, -)
        base_lines=$(awk -F'|' -v s="$sel" '$1=="base" && $2==s {print $3}' "$TMP/${name}.selectors" | paste -sd, -)
        fail "$name: '$sel' está dentro de un @media (líneas $media_lines) Y sin condición más abajo (líneas $base_lines) — la regla incondicional puede ganar en ese breakpoint, ver 1.1 de AUDITORIA_SONNET.md"
    done < "$TMP/${name}.media_then_base"
done
[ "$EXIT_CODE" -eq 0 ] && ok "sin selectores duplicados ni reglas incondicionales pisando un @media"

section "3. Clases CSS sin referencia en templates/ ni content/"

for css in "$CSS_DIR"/*.css; do
    name="$(basename "$css")"
    # Todas las clases mencionadas en líneas que abren una regla (antes de "{")
    grep -oE '^[^{]*\{' "$css" | grep -oE '\.[a-zA-Z][a-zA-Z0-9_-]*' | sort -u | while read -r cls; do
        token="${cls#.}"
        if ! grep -rlq -- "$token" "$TEMPLATES_DIR" "$CONTENT_DIR" 2>/dev/null; then
            warn "$name: '$cls' no aparece en ningún template ni archivo de contenido"
        fi
    done
done

section "4. Densidad de !important por archivo (informativo, no falla el audit)"
for css in "$CSS_DIR"/*.css; do
    count=$(grep -o '!important' "$css" | wc -l | tr -d ' ')
    echo "  $(basename "$css"): $count"
done

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    ok "audit-css.sh: sin problemas de cascada detectados"
else
    fail "audit-css.sh: revisar los hallazgos de arriba antes de commitear"
fi
exit $EXIT_CODE
