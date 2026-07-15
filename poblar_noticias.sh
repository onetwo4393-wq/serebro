#!/usr/bin/env bash
# poblar_noticias.sh — SerEbro
# Busca videos recientes del canal de Jorge Ebro por peleador
# y genera archivos .md con youtube_id en la sección correcta.
# Uso: ./poblar_noticias.sh [--limit N] [--dry-run]
# Requiere: yt-dlp, python3

set -euo pipefail

CANAL="https://www.youtube.com/@SerEbroEnlosDeportes/videos"
BASE="$(cd "$(dirname "$0")" && pwd)"
CONTENT="$BASE/content"
LIMIT=100
DRY_RUN=false
CACHE="/tmp/serebro_videos.json"

for arg in "$@"; do
    case $arg in
        --limit=*) LIMIT="${arg#*=}" ;;
        --dry-run)  DRY_RUN=true ;;
    esac
done

echo "[ SerEbro ] Descargando metadata de los últimos $LIMIT videos..."
yt-dlp --flat-playlist --dump-json --playlist-end "$LIMIT" "$CANAL" 2>/dev/null > "$CACHE"
echo "[ SerEbro ] OK — $(wc -l < "$CACHE") videos en caché"

declare -a PELEADORES=(
    "justin-gaethje|ufc|gaethje,gaetje"
    "canelo-alvarez|boxeo|canelo,alvarez"
    "max-holloway|ufc|holloway,blessed"
    "islam-makhachev|ufc|makhachev,islam"
    "ilia-topuria|ufc|topuria,matador"
    "conor-mcgregor|ufc|mcgregor,conor"
    "alex-pereira|ufc|pereira,poatan"
    "paddy-pimblett|ufc|pimblett,paddy,baddy"
    "teofimo-lopez|boxeo|teofimo,lopez"
    "david-benavides|boxeo|benavides,benavidez,david"
    "terence-crawford|boxeo|crawford,bud"
    "patricio-freire|mma|pitbull,patricio,freire"
    "anatoly-malykhin|mma|malykhin,anatoly"
    "adriano-moraes|mma|moraes,adriano"
)

buscar_video() {
    local keywords="$1"
    python3 - "$CACHE" "$keywords" << 'PYEOF'
import sys, json

cache_path = sys.argv[1]
keywords = [k.strip().lower() for k in sys.argv[2].split(",")]

best = None
best_views = -1

with open(cache_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            v = json.loads(line)
        except Exception:
            continue
        title = (v.get("title") or "").lower()
        views = v.get("view_count") or 0
        if any(kw in title for kw in keywords):
            if views > best_views:
                best_views = views
                best = v

if best:
    print(best['id'] + '::SEP::' + best['title'] + '::SEP::' + str(best_views))
else:
    print("NONE")
PYEOF
}

slugify() {
    echo "$1" | python3 -c "
import sys, re, unicodedata
s = sys.stdin.read().strip()
s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()
s = s.lower()
s = re.sub(r'[^a-z0-9]+', '-', s)
s = s.strip('-')
print(s[:60])
"
}

generar_md() {
    local slug_peleador="$1"
    local seccion="$2"
    local youtube_id="$3"
    local titulo_video="$4"
    local views="$5"

    local fecha
    fecha=$(date +%Y-%m-%d)

    local titulo_limpio
    titulo_limpio=$(echo "$titulo_video" | python3 -c "
import sys, re
t = sys.stdin.read().strip()
t = t.encode('ascii', 'ignore').decode()
t = re.sub(r'#\w+', '', t)
t = re.sub(r'[|]+', '-', t)
t = t.replace('"', '')
t = re.sub(r'\s+', ' ', t).strip()
print(t[:120])
")

    local slug_nota
    slug_nota=$(slugify "$titulo_limpio")
    slug_nota="${slug_peleador}-${slug_nota:0:60}"

    local filepath="$CONTENT/$seccion/${slug_nota}.md"

    if [[ -f "$filepath" ]]; then
        echo "  [ SKIP ] Ya existe: $filepath"
        return
    fi

    local descripcion="Jorge Ebro analiza: $titulo_limpio."

    if $DRY_RUN; then
        echo "  [ DRY ] $filepath"
        echo "          ID=$youtube_id | Views=$views"
        echo "          Título: $titulo_limpio"
    else
        cat > "$filepath" << MDEOF
+++
title = "$titulo_limpio"
date = $fecha
description = "$descripcion"
[extra]
destacado = false
youtube_id = "$youtube_id"
protagonista = "$slug_peleador"
+++
$descripcion
MDEOF
        echo "  [ OK ] $filepath (views: $views)"
    fi
}

echo ""
echo "[ SerEbro ] Procesando peleadores..."
echo ""

generados=0
sin_video=0

for entrada in "${PELEADORES[@]}"; do
    IFS='|' read -r slug seccion keywords <<< "$entrada"
    printf "  %-25s (%s) → " "$slug" "$seccion"
    resultado=$(buscar_video "$keywords")

    if [[ "$resultado" == "NONE" ]]; then
        echo "sin video encontrado"
        (( sin_video++ )) || true
        continue
    fi

    yt_id=$(echo "$resultado" | python3 -c "import sys; p=sys.stdin.read().strip().split('::SEP::'); print(p[0])")
    titulo=$(echo "$resultado" | python3 -c "import sys; p=sys.stdin.read().strip().split('::SEP::'); print(p[1])")
    views=$(echo "$resultado" | python3 -c "import sys; p=sys.stdin.read().strip().split('::SEP::'); print(p[2])")
    echo "encontrado (views: $views)"
    generar_md "$slug" "$seccion" "$yt_id" "$titulo" "$views"
    (( generados++ )) || true
done

echo ""
echo "[ SerEbro ] Listo. Generados: $generados | Sin video: $sin_video"
