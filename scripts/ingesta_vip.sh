#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: Faltan argumentos."
    echo "Uso: ./ingesta_vip.sh <URL_PLAYLIST> <CARPETA_DESTINO>"
    exit 1
fi

URL="$1"
SECCION="${2:-exclusivas}"
VIPS="topuria|masvidal|romero|canelo|gallo|volkanovski|mcgregor"

echo "Escaneando VIPs y sanitizando títulos..."

yt-dlp --flat-playlist --print "%(upload_date)s|%(id)s|%(title)s" "$URL" | grep -iE "$VIPS" | while IFS="|" read -r FECHA_CRUDA ID_VIDEO TITULO; do
    
    if [ -z "$ID_VIDEO" ] || [ "$ID_VIDEO" == "NA" ]; then
        continue
    fi

    if [ -z "$FECHA_CRUDA" ] || [ "$FECHA_CRUDA" == "NA" ]; then
        FECHA_CRUDA="20260710"
    fi

    FECHA="${FECHA_CRUDA:0:4}-${FECHA_CRUDA:4:2}-${FECHA_CRUDA:6:2}"
    ARCHIVO="content/${SECCION}/${ID_VIDEO}.md"

    # EL PARCHE: Eliminar comillas dobles del título usando expansión nativa de Bash
    TITULO_LIMPIO="${TITULO//\"/}"

    if [ ! -f "$ARCHIVO" ]; then
        cat <<PLANTILLA > "$ARCHIVO"
+++
title = "${TITULO_LIMPIO}"
date = ${FECHA}
template = "seccion.html"
+++

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; border-radius: 8px; margin-bottom: 20px;">
    <iframe src="https://www.youtube.com/embed/${ID_VIDEO}" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

Entrevista VIP exclusiva extraída automáticamente.
PLANTILLA
        echo "⭐ VIP Creado: $TITULO_LIMPIO"
    else
        echo "⏭ Omitido: $TITULO_LIMPIO"
    fi
done
