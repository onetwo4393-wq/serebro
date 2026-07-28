#!/usr/bin/env bash
# audit-frontmatter.sh — SerEbro
#
# Detecta los dos patrones de bug de datos ya encontrados en
# content/protagonistas/*.md (ver AUDITORIA_SONNET.md 2.2 y 2.3):
#   1. "rating" declarado como número sin comillas (Canelo tenía
#      rating = 98 en vez de rating = "98", único caso distinto al resto).
#   2. "nacionalidad" que no matchea ninguno de los países explícitos del
#      macro carta_peleador (macros.html) ni contiene "Estados Unidos" —
#      cae silenciosamente en la bandera de EE.UU. por defecto (el bug de
#      Paddy Pimblett/Yoel Romero, ya arreglado para esos dos).
#
# La lista de países conocidos se lee del propio macros.html en vez de
# estar hardcodeada acá, para que si alguien agrega un país nuevo al
# template, este script lo detecte automáticamente sin tocarlo.
#
# Uso: ./scripts/audit-frontmatter.sh
# Exit code 0 si no encuentra nada grave, 1 si encuentra un "rating" mal
# tipado (los de nacionalidad son warning, no fallan el build — pueden ser
# un fallback intencional, requieren criterio humano).
# Requiere: bash, grep, awk. (Nota para cuando esté "yq" disponible: ver
# scripts/README.md, sección "cuando llegue yq".)

set -uo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
CONTENT_DIR="$BASE/content/protagonistas"
MACROS="$BASE/templates/macros.html"
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

section "1. Campo 'rating' declarado sin comillas (debe ser string)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FOUND_BAD_RATING=0

for f in "$CONTENT_DIR"/*.md; do
    line=$(grep -E '^rating[ \t]*=' "$f" || true)
    [ -z "$line" ] && continue
    # rating = 98        -> mal (número pelado)
    # rating = "98"      -> bien (string)
    if echo "$line" | grep -qE '=\s*[0-9]'; then
        FOUND_BAD_RATING=1
        val=$(echo "$line" | grep -oE '[0-9]+')
        fail "$(basename "$f"): 'rating' está sin comillas — debe ser rating = \"$val\" para coincidir con el tipo de dato del resto de los protagonistas"
    fi
done
[ "$FOUND_BAD_RATING" -eq 0 ] && ok "todos los 'rating' son strings consistentes"

section "2. Campo 'nacionalidad' sin bandera mapeada en macros.html"

# Extrae los países soportados por "containing" y por igualdad exacta del
# macro carta_peleador, directamente del template — no hardcodeado acá.
grep -oE 'is containing\("[^"]+"\)' "$MACROS" | grep -oE '"[^"]+"' | tr -d '"' > "$TMP/known_containing"
grep -oE 'nacionalidad == "[^"]+"' "$MACROS" | grep -oE '"[^"]+"$' | tr -d '"' > "$TMP/known_exact"

FOUND_UNMAPPED=0
for f in "$CONTENT_DIR"/*.md; do
    nac=$(grep -E '^nacionalidad[ \t]*=' "$f" | sed -E 's/^nacionalidad[ \t]*=[ \t]*"([^"]*)".*/\1/')
    [ -z "$nac" ] && continue

    matched=false
    while read -r kw; do
        [ -z "$kw" ] && continue
        case "$nac" in *"$kw"*) matched=true ;; esac
    done < "$TMP/known_containing"
    while read -r kw; do
        [ -z "$kw" ] && continue
        [ "$nac" = "$kw" ] && matched=true
    done < "$TMP/known_exact"
    case "$nac" in *"Estados Unidos"*) matched=true ;; esac

    if [ "$matched" = false ]; then
        FOUND_UNMAPPED=1
        warn "$(basename "$f"): nacionalidad=\"$nac\" no matchea ningún país conocido de macros.html ni contiene \"Estados Unidos\" — cae silenciosamente en la bandera de EE.UU. (carta-us) por defecto. Verificar si es intencional."
    fi
done
[ "$FOUND_UNMAPPED" -eq 0 ] && ok "toda nacionalidad declarada resuelve a una bandera explícita (o a Estados Unidos)"

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    ok "audit-frontmatter.sh: sin problemas de tipo de dato detectados"
else
    fail "audit-frontmatter.sh: revisar los hallazgos de arriba antes de commitear"
fi
exit $EXIT_CODE
