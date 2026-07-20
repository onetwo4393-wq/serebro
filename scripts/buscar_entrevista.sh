#!/bin/bash
CANAL="https://www.youtube.com/@SerEbroEnlosDeportes"
NOMBRE="${1}"

if [ -z "$NOMBRE" ]; then
    echo "Uso: ./buscar_entrevista.sh 'Ilia Topuria'"
    exit 1
fi

echo "Buscando entrevistas de '$NOMBRE' en el canal de Jorge Ebro..."
echo ""

yt-dlp --no-download --flat-playlist \
    --match-filter "title ~= '(?i)$NOMBRE'" \
    --print "%(view_count)s|%(id)s|%(title)s" \
    "$CANAL/videos" 2>/dev/null | \
    sort -t'|' -k1 -rn | \
    head -5 | \
    awk -F'|' '{printf "Views: %s\nURL: https://youtu.be/%s\nTítulo: %s\n\n", $1, $2, $3}'
