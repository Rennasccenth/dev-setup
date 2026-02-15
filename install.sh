#!/usr/bin/env bash

# dev-setup - OS Router
# Detecta o sistema operacional e redireciona para o instalador apropriado
# Uso: curl -fsSL https://raw.githubusercontent.com/USER/dev-setup/main/install.sh | bash

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Dev Setup - Universal Installer${NC}"
echo ""

# Detectar sistema operacional
detect_os() {
    local os_name="$(uname -s)"
    case "${os_name}" in
        Linux*)
            echo "Linux"
            ;;
        Darwin*)
            echo "macOS"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

OS=$(detect_os)

echo -e "${GREEN}✓ Sistema operacional detectado: ${OS}${NC}"
echo ""

# Redirecionar para instalador apropriado
case "${OS}" in
    Windows)
        echo -e "${YELLOW}⚠ Detectado Git Bash no Windows${NC}"
        echo -e "${YELLOW}Para melhor compatibilidade, use o instalador PowerShell:${NC}"
        echo ""
        echo -e "${BLUE}iwr -useb https://raw.githubusercontent.com/USER/dev-setup/main/install.ps1 | iex${NC}"
        echo ""
        echo -e "${YELLOW}Ou execute diretamente o instalador do Windows:${NC}"
        echo -e "${BLUE}curl -fsSL https://raw.githubusercontent.com/USER/dev-setup/main/windows-dev-setup/install.ps1 -o install-windows.ps1${NC}"
        echo -e "${BLUE}powershell -ExecutionPolicy Bypass -File install-windows.ps1${NC}"
        echo ""
        exit 0
        ;;

    Linux)
        echo -e "${YELLOW}🔧 Instalador Linux em desenvolvimento...${NC}"
        echo ""
        echo -e "${BLUE}Em breve: suporte completo para distribuições Linux${NC}"
        echo -e "  - Detecção automática de distro (Ubuntu, Fedora, Arch, etc.)"
        echo -e "  - Instalação de pacotes via apt/dnf/pacman"
        echo -e "  - Configuração de dotfiles"
        echo -e "  - Setup de ambientes de desenvolvimento"
        echo ""
        echo -e "${YELLOW}Por enquanto, use o instalador Windows se estiver no WSL${NC}"
        exit 1
        ;;

    macOS)
        echo -e "${YELLOW}🍎 Instalador macOS em desenvolvimento...${NC}"
        echo ""
        echo -e "${BLUE}Em breve: suporte completo para macOS${NC}"
        echo -e "  - Instalação via Homebrew"
        echo -e "  - Configuração de Xcode Command Line Tools"
        echo -e "  - Setup de ambientes de desenvolvimento"
        echo ""
        exit 1
        ;;

    Unknown)
        echo -e "${RED}❌ Sistema operacional não suportado: $(uname -s)${NC}"
        echo ""
        echo -e "Sistemas suportados:"
        echo -e "  - ${GREEN}✓ Windows${NC} (via PowerShell)"
        echo -e "  - ${YELLOW}🔲 Linux${NC} (em desenvolvimento)"
        echo -e "  - ${YELLOW}🔲 macOS${NC} (em desenvolvimento)"
        exit 1
        ;;
esac
