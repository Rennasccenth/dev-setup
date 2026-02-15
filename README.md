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

## 🔒 Requisito: Autenticação GitHub via Bitwarden

Este instalador acessa **repositórios privados** de configuração para cada sistema operacional. Por isso, **Bitwarden CLI é obrigatório** para armazenar e obter seu GitHub Personal Access Token de forma segura.

### ⚙️ Setup Inicial (Apenas 1x)

#### 1. Instale Bitwarden CLI

**Windows:**
```powershell
winget install Bitwarden.CLI
```

**Linux/macOS:**
```bash
# Via npm (requer Node.js)
npm install -g @bitwarden/cli

# Ou via package manager específico
# Snap (Linux)
sudo snap install bw

# Homebrew (macOS)
brew install bitwarden-cli
```

#### 2. Faça Login no Bitwarden

```bash
bw login
```

Você será solicitado a inserir:
- Email da conta Bitwarden
- Master password

#### 3. Desbloqueie o Vault

```bash
bw unlock
```

Copie a session key retornada e exporte:

**Windows (PowerShell):**
```powershell
$env:BW_SESSION = "<session-key-aqui>"
```

**Linux/macOS (Bash/Zsh):**
```bash
export BW_SESSION="<session-key-aqui>"
```

⚠️ **Importante:** Você precisará executar `bw unlock` e exportar `BW_SESSION` toda vez que abrir um novo terminal.

#### 4. Crie um GitHub Personal Access Token (PAT)

1. Acesse: https://github.com/settings/tokens/new
2. Configurações do token:
   - **Nome:** `Dev Setup Token`
   - **Expiration:** Escolha duração (recomendado: 90 dias)
   - **Scopes:** Selecione **`repo`** (Full control of private repositories)
3. Clique em **Generate token**
4. **COPIE O TOKEN** (você não poderá vê-lo novamente!)

#### 5. Armazene o PAT no Bitwarden

**Opção A: Via Web Vault (Recomendado)**

1. Acesse https://vault.bitwarden.com/
2. Crie novo item:
   - **Name:** `GitHubDevSetup`
   - **Type:** Login ou Secure Note
3. Adicione campo customizado:
   - Clique em **"+ New custom field"**
   - **Field name:** `github-pat`
   - **Field type:** **Hidden**
   - **Value:** Cole o PAT que você copiou
4. Salve o item

**Opção B: Via CLI**

**Windows (PowerShell):**
```powershell
# Obter template de item
$item = bw get template item | ConvertFrom-Json

# Configurar nome e tipo
$item.name = "GitHubDevSetup"
$item.type = 2  # Secure Note

# Adicionar campo customizado
$field = @{
    name = "github-pat"
    value = "ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Seu PAT aqui
    type = 1  # Hidden
}
$item.fields = @($field)

# Criar item no vault
$item | ConvertTo-Json | bw encode | bw create item
```

**Linux/macOS (Bash):**
```bash
# Obter template e criar item
bw get template item | jq \
  '.name = "GitHubDevSetup" |
   .type = 2 |
   .fields = [{
     "name": "github-pat",
     "value": "ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
     "type": 1
   }]' | bw encode | bw create item
```

#### 6. Sincronize o Vault (se usar app desktop/móvel)

```bash
bw sync
```

### ✅ Validar Setup

Antes de executar o instalador, você pode validar se tudo está configurado corretamente:

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/validate-setup.ps1 | iex
```

Ou com mais detalhes:
```powershell
iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/validate-setup.ps1 | iex -Args "-Verbose"
```

Este script verifica:
- ✅ Bitwarden CLI instalado e desbloqueado
- ✅ Item `GitHubDevSetup` existe no vault
- ✅ Campo `github-pat` configurado corretamente
- ✅ GitHub CLI disponível (opcional, pode ser instalado automaticamente)
- ✅ winget disponível (necessário para auto-install do gh)

### 🚀 Agora você está pronto!

Execute o one-liner correspondente ao seu sistema operacional (veja seção acima).

O instalador irá:
1. ✅ Verificar se Bitwarden está desbloqueado
2. ✅ Obter seu GitHub PAT do vault
3. ✅ Instalar GitHub CLI (se necessário)
4. ✅ Autenticar no GitHub
5. ✅ Clonar repositório privado de configuração do seu SO
6. ✅ Executar instalação completa

### 🔧 Troubleshooting

**Erro: "Bitwarden CLI não está disponível ou desbloqueado"**

```bash
# Desbloqueie o vault
bw unlock

# Exporte a session key retornada
export BW_SESSION="<session-key>"  # Linux/macOS
$env:BW_SESSION = "<session-key>"   # Windows
```

**Erro: "GitHub PAT não encontrado no Bitwarden"**

Certifique-se de que:
- O item no vault se chama exatamente **`GitHubDevSetup`**
- O campo customizado se chama exatamente **`github-pat`**
- O tipo do campo é **Hidden**

**Erro: "GitHub PAT inválido ou expirado"**

1. Verifique se o token tem scope **`repo`**
2. Verifique se o token não expirou
3. Crie um novo token: https://github.com/settings/tokens/new
4. Atualize o valor no Bitwarden vault

**Erro: "GitHub CLI não encontrado"**

**Windows:**
```powershell
winget install GitHub.cli
```

**Linux/macOS:**
```bash
# Homebrew
brew install gh

# Ou via package manager
# Ubuntu/Debian
sudo apt install gh

# Fedora
sudo dnf install gh
```

### 🔓 Modo Público (Fallback)

Se você está usando repositórios públicos e não precisa de autenticação, pode usar:

```powershell
# Windows - modo público
iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.ps1 | iex -Args "-ForcePublic"
```

⚠️ **Nota:** O modo público não funcionará se os repositórios OS-específicos forem privados.

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

**Repositório:** [rennasccenth/dev-setup-windows](https://github.com/rennasccenth/dev-setup-windows) (privado)

> **Nota:** Use o instalador universal acima (com autenticação Bitwarden) para acesso automático ao repositório privado.

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
