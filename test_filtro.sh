#!/bin/bash

URL="https://www.youtube.com/playlist?list=PLnA3uH8vBpm220HUmKNFDS4TIOqEIhjlo"

echo "🧪 Iniciando laboratorio: analizando los últimos 3 videos..."
echo "=============================================================="

# LA SOLUCIÓN: Filtramos desde el propio yt-dlp con --playlist-end 3 para evitar el Broken pipe
yt-dlp --flat-playlist --playlist-end 3 --print "%(id)s|%(title)s" "$URL" | while IFS="|" read -r ID_VIDEO TITULO; do
    
    if [ -z "$ID_VIDEO" ] || [ "$ID_VIDEO" == "NA" ]; then
        continue
    fi

    echo -e "\n🎬 Analizando: $TITULO"
    echo "⏳ Bajando transcripción en segundo plano..."

    # Descarga silenciosa de la transcripción
    yt-dlp --write-auto-sub --skip-download --sub-lang es --convert-subs vtt "https://www.youtube.com/watch?v=$ID_VIDEO" -o "test_${ID_VIDEO}.vtt" >/dev/null 2>&1

    FILE="test_${ID_VIDEO}.vtt.es.vtt"

    if [ -f "$FILE" ]; then
        # Contamos cuántas veces se habla de cosas importantes (Puntaje)
        PUNTAJE=$(grep -iE "revancha|estrategia|recuperación|plan|nocaut|ko|título|cinturón|entrevista" "$FILE" | wc -l)
        echo "📊 Puntaje de sustancia: $PUNTAJE menciones de alto valor."

        # Clasificador Inteligente
        CONTEO_UFC=$(grep -iE "ufc|topuria|masvidal|volkanovski|mcgregor|canelo" "$FILE" | wc -l)
        CONTEO_MMA=$(grep -iE "mma|bellator|pfl|one championship" "$FILE" | wc -l)

        if [ "$PUNTAJE" -gt 3 ]; then
            if [ "$CONTEO_UFC" -ge "$CONTEO_MMA" ]; then
                SECCION="ufc"
            else
                SECCION="mma"
            fi
            echo "✅ ¡SANGRE PURA! Pasa el filtro."
            echo "📁 Clasificado en: content/${SECCION}/"
            echo "🖼️ URL de Miniatura: https://img.youtube.com/vi/${ID_VIDEO}/hqdefault.jpg"
        else
            echo "❌ DESCARTADO: Puro humo o contenido superficial."
        fi
        
        # Limpieza quirúrgica de temporales
        rm "$FILE"
    else
        echo "⚠️ No se pudo obtener la transcripción de este video."
    fi
    echo "--------------------------------------------------"
done
