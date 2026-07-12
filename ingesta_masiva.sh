#!/bin/bash

# 1. Comprobar que pasaste una URL
if [ -z "$1" ]; then
    echo "Error: Faltan argumentos."
    echo "Uso: ./ingesta_masiva.sh <URL_PLAYLIST> <CARPETA_DESTINO>"
    echo "Ejemplo: ./ingesta_masiva.sh 'https://youtube.com/playlist?list=...' exclusivas"
    exit 1
fi

URL="$1"
SECCION="${2:-exclusivas}" # Por defecto va a 'exclusivas' si no le pasas el segundo parámetro

echo "Escaneando lista de reproducción... (Esto tomará unos segundos)"

# 2. Usar --flat-playlist para extraer metadatos sin descargar NINGÚN video, súper rápido
yt-dlp --flat-playlist --print "%(title)s|%(id)s|%(upload_date)s" "$URL" | while IFS="|" read -r TITULO ID_VIDEO FECHA_CRUDA; do
    
    # Ignorar videos privados o borrados que devuelven datos vacíos
    if [ -z "$ID_VIDEO" ] || [ "$ID_VIDEO" == "NA" ]; then
        continue
    fi

    # Formatear la fecha
    FECHA="${FECHA_CRUDA:0:4}-${FECHA_CRUDA:4:2}-${FECHA_CRUDA:6:2}"
    ARCHIVO="content/${SECCION}/${ID_VIDEO}.md"

    # 3. Lógica de seguridad: Solo crea el archivo si no existe previamente
    if [ ! -f "$ARCHIVO" ]; then
        cat <<PLANTILLA > "$ARCHIVO"
+++
title = "${TITULO}"
date = ${FECHA}
template = "seccion.html"
+++

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; border-radius: 8px; margin-bottom: 20px;">
    <iframe src="https://www.youtube.com/embed/${ID_VIDEO}" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

Entrevista extraída automáticamente del canal de Jorge Ebro. Reproduce el video para conocer todos los detalles.
PLANTILLA
        echo "✔ Creado: $TITULO"
    else
        echo "⏭ Omitido (Ya existe): $TITULO"
    fi
done

echo "==================================="
echo "¡Ingesta masiva finalizada!"
