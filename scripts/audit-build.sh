#!/usr/bin/env bash
# audit-build.sh — SerEbro
#
# Smoke test post-build: corre "zola build" y confirma que las rutas clave
# del sitio realmente existen y contienen lo esperado. "El build no tira
# error" no es lo mismo que "el sitio sirve lo que debería" — este script
# chequea lo segundo.
#
# Uso: ./scripts/audit-build.sh
# Exit code 0 si todo OK, 1 si falla el build o falta alguna ruta/contenido.
# Requiere: zola, grep.

set -uo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC="$BASE/public"
EXIT_CODE=0

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

fail() { echo -e "${RED}✗${NC} $1"; EXIT_CODE=1; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
section() { echo -e "\n${BOLD}== $1 ==${NC}"; }

section "1. zola build"
if ! command -v zola >/dev/null 2>&1; then
    fail "zola no está instalado o no está en PATH"
    exit 1
fi

cd "$BASE"
TMPLOG="$(mktemp)"
trap 'rm -f "$TMPLOG"' EXIT

if zola build > "$TMPLOG" 2>&1; then
    ok "zola build terminó sin errores"
else
    fail "zola build falló:"
    cat "$TMPLOG"
    exit 1
fi

section "2. Rutas clave existen y sirven contenido esperado"

# ruta:string_esperado — el string confirma que la página no está vacía/rota,
# no solo que el archivo existe.
# Nota: eventos/ y exclusivas/ NO están acá a propósito — sus _index.md
# tienen "render = false" (Zola no genera listing page para esas
# secciones, solo las páginas individuales de adentro). Si eso cambia,
# agregar la ruta correspondiente.
declare -a CHECKS=(
    "index.html:Los Protagonistas"
    "ufc/index.html:UFC"
    "boxeo/index.html:Boxeo"
    "mma/index.html:MMA"
    "protagonistas/index.html:Protagonistas"
    "sobre-jorge/index.html:Jorge Ebro"
    "contacto/index.html:Contacto"
)

for check in "${CHECKS[@]}"; do
    route="${check%%:*}"
    expected="${check#*:}"
    path="$PUBLIC/$route"
    if [ ! -f "$path" ]; then
        fail "falta $route en public/"
        continue
    fi
    if grep -q "$expected" "$path"; then
        ok "$route contiene '$expected'"
    else
        fail "$route existe pero no contiene '$expected' esperado"
    fi
done

section "3. CSS y assets críticos compilados"

for asset in assets/css/style.css assets/css/dark-mode.css; do
    if [ -f "$PUBLIC/$asset" ]; then
        ok "$asset presente en public/"
    else
        fail "falta $asset en public/"
    fi
done

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    ok "audit-build.sh: sitio compila y las rutas clave sirven contenido"
else
    fail "audit-build.sh: hay rutas rotas o vacías, revisar arriba"
fi
exit $EXIT_CODE
