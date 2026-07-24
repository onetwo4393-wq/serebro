#!/bin/bash

# cleanup-images.sh — Detecta y propone limpiar imágenes duplicadas
# Uso: ./scripts/cleanup-images.sh [--dry-run] [--force]
#
# Sin flags: Solo lista duplicados encontrados
# --dry-run: Simula eliminación (no borra nada)
# --force:   Borra duplicados (SIN CONFIRMACIÓN)

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Flags
DRY_RUN=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true; shift ;;
    *)         echo "Uso: $0 [--dry-run] [--force]"; exit 1 ;;
  esac
done

echo "================================================"
echo "  Cleanup de imágenes duplicadas"
echo "================================================"
echo ""

# Array de directorios a escanear
declare -a DIRS=(
  "static/assets/img/protagonistas"
  "static/assets/img/hero"
  "static/assets/img"
)

TOTAL_DELETED=0
TOTAL_SIZE=0

for DIR in "${DIRS[@]}"; do
  if [ ! -d "$DIR" ]; then
    continue
  fi

  echo "📁 Escaneando: $DIR"

  # Encontrar archivos sin extensión duplicados (jpg + webp)
  # Agrupa por nombre base y detecta pares jpg/webp
  find "$DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.webp" \) | sed 's/\.[^.]*$//' | sort | uniq -d | while read -r base; do

    jpg_file="${base}.jpg"
    webp_file="${base}.webp"

    # Verificar que ambos existen
    if [ -f "$jpg_file" ] && [ -f "$webp_file" ]; then
      jpg_size=$(stat -f%z "$jpg_file" 2>/dev/null || stat -c%s "$jpg_file" 2>/dev/null || echo "0")
      webp_size=$(stat -f%z "$webp_file" 2>/dev/null || stat -c%s "$webp_file" 2>/dev/null || echo "0")

      echo ""
      echo -e "${YELLOW}⚠️  Duplicado encontrado:${NC}"
      echo "   📷 JPG:  $(basename "$jpg_file") ($(numfmt --to=iec $jpg_size 2>/dev/null || echo "$jpg_size bytes"))"
      echo "   📷 WEBP: $(basename "$webp_file") ($(numfmt --to=iec $webp_size 2>/dev/null || echo "$webp_size bytes"))"

      # Propuesta: eliminar .jpg (mantener .webp como estándar)
      if [ "$FORCE" = true ]; then
        rm "$jpg_file"
        echo -e "${GREEN}✓ Eliminado: $(basename "$jpg_file")${NC}"
        TOTAL_DELETED=$((TOTAL_DELETED + 1))
        TOTAL_SIZE=$((TOTAL_SIZE + jpg_size))
      elif [ "$DRY_RUN" = true ]; then
        echo -e "${GREEN}[DRY-RUN] Se eliminaría: $(basename "$jpg_file")${NC}"
        TOTAL_DELETED=$((TOTAL_DELETED + 1))
        TOTAL_SIZE=$((TOTAL_SIZE + jpg_size))
      else
        echo -e "   ${GREEN}→ Recomendación: eliminar .jpg (mantener .webp)${NC}"
      fi
    fi
  done
done

echo ""
echo "================================================"

if [ "$TOTAL_DELETED" -gt 0 ]; then
  size_readable=$(numfmt --to=iec $TOTAL_SIZE 2>/dev/null || echo "$TOTAL_SIZE bytes")

  if [ "$FORCE" = true ]; then
    echo -e "${GREEN}✓ Limpeza completada${NC}"
    echo "   Archivos eliminados: $TOTAL_DELETED"
    echo "   Espacio liberado: $size_readable"
  elif [ "$DRY_RUN" = true ]; then
    echo -e "${GREEN}[DRY-RUN] Simulación completada${NC}"
    echo "   Archivos que se eliminarían: $TOTAL_DELETED"
    echo "   Espacio que se liberaría: $size_readable"
    echo ""
    echo "   Para ejecutar realmente:"
    echo "   ./scripts/cleanup-images.sh --force"
  else
    echo -e "${YELLOW}Detectados $TOTAL_DELETED duplicados${NC}"
    echo "   Espacio a recuperar: $size_readable"
    echo ""
    echo "   Para simular:"
    echo "   ./scripts/cleanup-images.sh --dry-run"
    echo ""
    echo "   Para ejecutar (CUIDADO):"
    echo "   ./scripts/cleanup-images.sh --force"
  fi
else
  echo -e "${GREEN}✓ No se encontraron duplicados${NC}"
fi

echo "================================================"
echo ""
