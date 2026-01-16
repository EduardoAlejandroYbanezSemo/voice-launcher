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

# Crear directorios de configuración
CONFIG_DIR_SYSTEM="/etc/voice-launcher"
CONFIG_DIR_USER="$HOME/.config/voice-launcher"

# Usar configuración de usuario (más fácil de editar)
mkdir -p "$CONFIG_DIR_USER"

# Copiar commands.json
if [ -f "commands.json" ]; then
    cp commands.json "$CONFIG_DIR_USER/commands.json"
    echo -e "${GREEN}✓${NC} commands.json copiado a $CONFIG_DIR_USER"
fi

# Copiar games.json
if [ -f "games.json" ]; then
    cp games.json "$CONFIG_DIR_USER/games.json"
    echo -e "${GREEN}✓${NC} games.json copiado a $CONFIG_DIR_USER"
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
echo -e "${YELLOW}📝 Archivos de configuración:${NC}"
echo -e "   • Comandos: ${BLUE}$CONFIG_DIR_USER/commands.json${NC}"
echo -e "   • Juegos:   ${BLUE}$CONFIG_DIR_USER/games.json${NC}"
echo -e "   • Imágenes: ${BLUE}$IMAGES_DIR${NC}"
echo ""
echo -e "${YELLOW}✏️  Para editar tu biblioteca de juegos:${NC}"
echo -e "   ${GREEN}nano $CONFIG_DIR_USER/games.json${NC}"
echo ""
echo -e "${YELLOW}🎮 Para ejecutar:${NC}"
echo -e "   ${GREEN}voice-launcher${NC}"
echo ""
echo -e "${YELLOW}🎙️ Palabra de activación: ${GREEN}\"Carrito\"${NC}"
echo ""
