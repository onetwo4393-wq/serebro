#!/bin/bash
# poblar_entrevistas.sh — SerEbro
# Pobla content/exclusivas/ con entrevistas del canal de Jorge Ebro.
# Uso: ./scripts/poblar_entrevistas.sh
# Requiere: yt-dlp, python3
CANAL="https://www.youtube.com/@SerEbroEnlosDeportes/videos"

declare -A PELEADORES
PELEADORES["justin-gaethje"]="Gaethje"
PELEADORES["canelo-alvarez"]="Canelo"
PELEADORES["max-holloway"]="Holloway"
PELEADORES["islam-makhachev"]="Makhachev"
PELEADORES["topuria"]="Topuria"
PELEADORES["alex-pereira"]="Pereira"
PELEADORES["paddy-pimblett"]="Pimblett"
PELEADORES["teofimo-lopez"]="Teofimo"
PELEADORES["david-benavides"]="Benavides"
PELEADORES["terence-crawford"]="Crawford"
PELEADORES["patricio-freire"]="Pitbull"
PELEADORES["anatoly-malykhin"]="Malykhin"
PELEADORES["adriano-moraes"]="Moraes"

for SLUG in "${!PELEADORES[@]}"; do
    NOMBRE="${PELEADORES[$SLUG]}"
    echo "→ Buscando videos de $NOMBRE..."

    RESULTADOS=$(yt-dlp --no-download --flat-playlist \
        --match-filter "title ~= '(?i)$NOMBRE'" \
        --print "%(view_count)s|%(id)s|%(title)s|%(upload_date)s" \
        --playlist-end 500 \
        "$CANAL" 2>/dev/null | sort -t'|' -k1 -rn | head -2)

    if [ -z "$RESULTADOS" ]; then
        echo "  Sin resultados para $NOMBRE"
        continue
    fi

    while IFS='|' read -r VIEWS ID TITULO FECHA_CRUDA; do
        FECHA="${FECHA_CRUDA:0:4}-${FECHA_CRUDA:4:2}-${FECHA_CRUDA:6:2}"
        ARCHIVO="content/exclusivas/${SLUG}-${ID}.md"
        if [ ! -f "$ARCHIVO" ]; then
            cat > "$ARCHIVO" << PLANTILLA
+++
title = "${TITULO}"
date = ${FECHA}
template = "page.html"
description = "Cobertura de Jorge Ebro sobre ${NOMBRE}."
[extra]
youtube_id = "${ID}"
protagonista = "${SLUG}"
+++
Cobertura de Jorge Ebro.
PLANTILLA
            echo "  ✓ Agregado: $TITULO"
        else
            echo "  — Ya existe: $ID"
        fi
    done <<< "$RESULTADOS"
done

echo ""
echo "Listo. Ejecutá: zola build"
