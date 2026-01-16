#!/bin/bash
# 📥 Descargador del modelo de Vosk para español
# Este script descarga automáticamente el modelo de reconocimiento de voz

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  📥 Descargando modelo de Vosk (Español)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# URL del modelo (pequeño, optimizado para Raspberry Pi)
MODEL_URL="https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip"
MODEL_ZIP="vosk-model-small-es-0.42.zip"
MODEL_DIR="vosk-model-small-es-0.42"

cd src-python

# Verificar si ya existe
if [ -d "model" ]; then
    echo -e "${YELLOW}⚠${NC} El modelo ya existe en src-python/model/"
    read -p "¿Deseas descargarlo de nuevo? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}→${NC} Usando modelo existente"
        exit 0
    fi
    rm -rf model
fi

# Descargar
echo -e "${BLUE}→${NC} Descargando modelo (${YELLOW}~40 MB${NC})..."
wget "$MODEL_URL" -O "$MODEL_ZIP"

# Descomprimir
echo -e "${BLUE}→${NC} Descomprimiendo..."
unzip -q "$MODEL_ZIP"

# Renombrar
mv "$MODEL_DIR" model

# Limpiar
rm "$MODEL_ZIP"

echo ""
echo -e "${GREEN}✓${NC} Modelo instalado en: ${BLUE}src-python/model/${NC}"
echo ""
echo -e "${YELLOW}Ahora puedes ejecutar:${NC} ${GREEN}./install-raspberry.sh${NC}"
echo ""
