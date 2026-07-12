#!/bin/bash

URL="https://www.youtube.com/playlist?list=PLnA3uH8vBpm220HUmKNFDS4TIOqEIhjlo"
POOL_TEMP="/tmp/ebro_pool.txt"
> "$POOL_TEMP"

echo "🦅 [BÚNKER-AI] Iniciando escaneo meritocrático con parche de fechas..."
echo "=============================================================="

yt-dlp --flat-playlist --playlist-end 25 --print "%(id)s|%(upload_date>%Y-%m-%d)s|%(title)s" "$URL" | while IFS="|" read -r ID_VIDEO FECHA TITULO; do
    
    if [ -z "$ID_VIDEO" ] || [ "$ID_VIDEO" == "NA" ]; then
        continue
    fi

    echo "⏳ Evaluando sustancia de: $TITULO"

    yt-dlp --write-auto-sub --skip-download --sub-lang es --convert-subs vtt "https://www.youtube.com/watch?v=$ID_VIDEO" -o "eval_${ID_VIDEO}.vtt" >/dev/null 2>&1
    FILE="eval_${ID_VIDEO}.vtt.es.vtt"

    if [ -f "$FILE" ]; then
        PUNTAJE=$(grep -iE "revancha|estrategia|recuperación|plan|nocaut|ko|título|cinturón|entrevista|exclusiva" "$FILE" | wc -l)
        echo "$PUNTAJE|$ID_VIDEO|$FECHA|$TITULO" >> "$POOL_TEMP"
        rm "$FILE"
    else
        echo "0|$ID_VIDEO|$FECHA|$TITULO" >> "$POOL_TEMP"
    fi
done

echo -e "\n🔥 [PROCESAMIENTO] Seleccionando las 9 joyas de la corona..."
echo "=============================================================="

# Limpiamos la carpeta (acá vuela el archivo corrupto)
find content/exclusivas/ -type f ! -name '_index.md' -delete

RANK=1
sort -t"|" -k1 -nr "$POOL_TEMP" | head -n 9 | while IFS="|" read -r SCORE ID_VIDEO FECHA TITULO; do
    
    # 🩹 EL PARCHE: Si la fecha es NA o está vacía, le metemos la fecha de hoy para que Zola no llore
    if [ "$FECHA" == "NA" ] || [ -z "$FECHA" ]; then
        FECHA=$(date +%Y-%m-%d)
    fi

    FILE_NAME=$(echo "$TITULO" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | cut -c1-50)
    
    echo "🥇 #$RANK [Score: $SCORE] -> content/exclusivas/${FILE_NAME}.md"

    cat << TOML > "content/exclusivas/${FILE_NAME}.md"
+++
title = "${TITULO//\"/\\\"}"
date = ${FECHA}
template = "seccion.html"

[extra]
youtube_id = "${ID_VIDEO}"
thumbnail = "https://img.youtube.com/vi/${ID_VIDEO}/hqdefault.jpg"
substancia_score = ${SCORE}
+++

Entrevista VIP exclusiva extraída automáticamente con un puntaje de relevancia de ${SCORE}.
TOML

    RANK=$((RANK+1))
done

rm -f "$POOL_TEMP"
echo -e "\n✨ [ÉXITO] Sección blindada y actualizada."
