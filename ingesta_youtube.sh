#!/bin/bash

# 1. Comprobar que pasaste una URL
if [ -z "$1" ]; then
    echo "Error: Debes proporcionar una URL de YouTube."
    echo "Uso: ./ingesta_youtube.sh <URL>"
    exit 1
fi

URL="$1"
SECCION="exclusivas"

echo "Conectando con YouTube para extraer metadatos..."

# 2. Extraer los datos ultrarrápido (sin descargas, sin listas, sin formatos)
DATOS=$(yt-dlp --no-download --no-playlist --print "%(title)s|%(id)s|%(upload_date)s" "$URL")

TITULO=$(echo "$DATOS" | awk -F'|' '{print $1}')
ID_VIDEO=$(echo "$DATOS" | awk -F'|' '{print $2}')
FECHA_CRUDA=$(echo "$DATOS" | awk -F'|' '{print $3}')

# 3. Formatear la fecha para Zola
FECHA="${FECHA_CRUDA:0:4}-${FECHA_CRUDA:4:2}-${FECHA_CRUDA:6:2}"

# 4. Crear el archivo Markdown
ARCHIVO="content/${SECCION}/${ID_VIDEO}.md"

cat <<PLANTILLA > "$ARCHIVO"
+++
title = "${TITULO}"
date = ${FECHA}
template = "seccion.html"
+++

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; border-radius: 8px; margin-bottom: 20px;">
    <iframe src="https://www.youtube.com/embed/${ID_VIDEO}" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

Entrevista exclusiva. Reproduce el video para conocer todos los detalles y el análisis profundo de Jorge Ebro.
PLANTILLA

echo "¡Éxito Total!"
echo "Generado: $ARCHIVO"
