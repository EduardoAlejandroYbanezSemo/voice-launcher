#!/bin/bash
# 🎮 Voice Launcher - Post-Instalación
# Instala el paquete .DEB y configura los archivos de juegos

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🎮 Voice Launcher - Post-Instalación                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detectar el paquete .DEB
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    DEB_FILE="src-tauri/target/release/bundle/deb/voice-launcher_0.1.0_arm64.deb"
else
    DEB_FILE="src-tauri/target/release/bundle/deb/voice-launcher_0.1.0_armhf.deb"
fi

# Verificar que existe el .DEB
if [ ! -f "$DEB_FILE" ]; then
    echo -e "${RED}✗${NC} No se encontró el archivo: $DEB_FILE"
    echo -e "${YELLOW}→${NC} Ejecuta primero: ./install-raspberry.sh"
    exit 1
fi

# Instalar el paquete
echo -e "${BLUE}[1/3]${NC} Instalando paquete .DEB..."
sudo dpkg -i "$DEB_FILE"

# Resolver dependencias faltantes (si las hay)
sudo apt-get install -f -y

echo -e "${GREEN}✓${NC} Paquete instalado"

# Copiar archivos de configuración
echo ""
echo -e "${BLUE}[2/3]${NC} Configurando archivos JSON..."

# Directorio de instalación (donde está el ejecutable)
INSTALL_DIR="/usr/bin"

# Copiar commands.json
if [ -f "commands.json" ]; then
    sudo cp commands.json "$INSTALL_DIR/commands.json"
    echo -e "${GREEN}✓${NC} commands.json copiado"
fi

# Copiar games.json
if [ -f "games.json" ]; then
    sudo cp games.json "$INSTALL_DIR/games.json"
    echo -e "${GREEN}✓${NC} games.json copiado"
fi

# Crear directorio para imágenes de juegos
IMAGES_DIR="$HOME/.local/share/voice-launcher/images"
mkdir -p "$IMAGES_DIR"

# Copiar imágenes de ejemplo (si existen)
if [ -d "public" ]; then
    cp -r public/* "$IMAGES_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Imágenes copiadas a $IMAGES_DIR"
fi

# Crear acceso directo en el escritorio
echo ""
echo -e "${BLUE}[3/3]${NC} Creando acceso directo..."

DESKTOP_FILE="$HOME/Desktop/Voice-Launcher.desktop"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Voice Launcher
Comment=Lanzador de juegos por voz
Exec=voice-launcher
Icon=gamepad
Terminal=false
Categories=Game;
EOF

chmod +x "$DESKTOP_FILE"
echo -e "${GREEN}✓${NC} Acceso directo creado en el escritorio"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ INSTALACIÓN COMPLETADA                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📝 Configuración:${NC}"
echo -e "   • Comandos: ${BLUE}$INSTALL_DIR/commands.json${NC}"
echo -e "   • Juegos:   ${BLUE}$INSTALL_DIR/games.json${NC}"
echo -e "   • Imágenes: ${BLUE}$IMAGES_DIR${NC}"
echo ""
echo -e "${YELLOW}🎮 Para ejecutar:${NC}"
echo -e "   ${GREEN}voice-launcher${NC}"
echo ""
echo -e "${YELLOW}🎙️ Palabra de activación: ${GREEN}\"Carrito\"${NC}"
echo ""
