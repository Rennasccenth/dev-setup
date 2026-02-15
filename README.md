# Dev Setup

Ferramentas de configuração automatizada de ambiente de desenvolvimento para múltiplos sistemas operacionais.

## 🎯 Objetivo

Ter **um único comando** que configure completamente seu ambiente de desenvolvimento, independente do sistema operacional.

## 🚀 Instalação Rápida (One-Liner Universal)

### Windows (PowerShell como Administrador)

```powershell
iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.ps1 | iex
```

### Linux / macOS / Git Bash

```bash
curl -fsSL https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.sh | bash
```

---

## 📦 Ferramentas Disponíveis

### ✅ Windows Dev Setup

**Status:** Implementado e funcional

**Recursos:**
- ✅ Seleção de gerenciador de pacotes (Winget, Chocolatey, Scoop)
- ✅ mise para gerenciar SDKs (.NET, Node.js, Python, etc.)
- ✅ Autenticação Git moderna (GitHub CLI, Azure DevOps CLI)
- ✅ Instalação de aplicativos essenciais (VS Code, Chrome, Terminal, etc.)
- ✅ Docker Desktop e WSL2
- ✅ Interface TUI interativa

**Documentação:** [windows-dev-setup/README.md](windows-dev-setup/README.md)

**Instalação direta:**
```powershell
iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/windows-dev-setup/install.ps1 | iex
```

---

### 🔲 Linux Dev Setup

**Status:** Planejado

**Recursos planejados:**
- Detecção automática de distribuição (Ubuntu, Fedora, Arch, etc.)
- Instalação via gerenciadores nativos (apt, dnf, pacman)
- Configuração de dotfiles
- Setup de SDKs via mise
- Configuração de Git e SSH

---

### 🔲 macOS Dev Setup

**Status:** Planejado

**Recursos planejados:**
- Instalação via Homebrew
- Xcode Command Line Tools
- Setup de SDKs via mise
- Configuração de Git e SSH
- Configurações do sistema

---

## 🏗️ Estrutura do Projeto

```
dev-setup/
├── install.sh              # Roteador shell (detecta SO)
├── install.ps1             # Roteador PowerShell (Windows)
├── README.md               # Este arquivo
├── windows-dev-setup/      # Ferramenta para Windows
│   ├── install.ps1
│   ├── src/
│   └── README.md
├── linux-dev-setup/        # (Futuro) Ferramenta para Linux
└── macos-dev-setup/        # (Futuro) Ferramenta para macOS
```

---

## 🔧 Como Funciona

1. **Detecção automática:** O script roteador detecta seu sistema operacional
2. **Redirecionamento:** Chama o instalador específico para seu SO
3. **Setup completo:** Cada instalador configura o ambiente de forma interativa

---

## 📚 Documentação

- [Windows Dev Setup](windows-dev-setup/README.md) - Ferramenta completa para Windows
- [Linux Dev Setup](linux-dev-setup/README.md) - Em desenvolvimento
- [macOS Dev Setup](macos-dev-setup/README.md) - Em desenvolvimento

---

## 🤝 Contribuindo

Este projeto é modular e aceita contribuições:

1. **Melhorar ferramentas existentes** (Windows)
2. **Adicionar suporte para Linux** (em desenvolvimento)
3. **Adicionar suporte para macOS** (em desenvolvimento)
4. **Adicionar novos componentes** às ferramentas existentes

---

## 📝 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes

---

**Feito com ❤️ para desenvolvedores que valorizam automação**
