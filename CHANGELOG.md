# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.0.0] - 2026-02-15

### 🚨 BREAKING CHANGES

- **Autenticação obrigatória via Bitwarden**: O instalador agora requer Bitwarden CLI para acessar repositórios privados de configuração OS-específicos
- Os repositórios de configuração (`windows-dev-setup`, `linux-dev-setup`, `macos-dev-setup`) foram movidos para repositórios privados separados
- Usuários precisam realizar setup inicial do Bitwarden antes de executar o instalador (veja [README.md](README.md#-requisito-autenticação-github-via-bitwarden))

### ✨ Adicionado

- **Autenticação GitHub via Bitwarden**: Integração completa com Bitwarden CLI para obter GitHub Personal Access Token de forma segura
- **Instalação automática do GitHub CLI**: Se `gh` não estiver instalado, o script instala automaticamente via winget
- **Modo público (fallback)**: Flag `-ForcePublic` para usar repositórios públicos (se disponíveis)
- **Parâmetro de teste**: Flag `-GitHubPAT` para passar PAT diretamente via linha de comando (útil para testes)
- **Funções auxiliares**:
  - `Test-BitwardenAvailable`: Verifica disponibilidade e status do Bitwarden CLI
  - `Get-BitwardenSecret`: Obtém secrets do vault Bitwarden
  - `Install-GitHubCLI`: Instala GitHub CLI automaticamente
  - `Set-GitHubAuthentication`: Autentica no GitHub usando PAT
  - `Get-PrivateOSRepository`: Clona repositório privado OS-específico
- **Mapeamento de repositórios por SO**: Arquitetura preparada para Linux e macOS (futuro)
- **Documentação completa**: Guia passo-a-passo de setup inicial do Bitwarden no README
- **Guia de testes**: Arquivo `TESTING.md` com 12 cenários de teste documentados
- **Tratamento de erros robusto**: Mensagens de erro detalhadas com sugestões de resolução

### 🔧 Modificado

- **Arquitetura do projeto**: Mudança de repo monolítico para repos separados por OS (público + privados)
- **Fluxo de instalação**: Agora clona repositório privado localmente ao invés de baixar via HTTP público
- **README.md**: Adicionada seção extensa sobre requisitos de autenticação e troubleshooting

### 🔒 Segurança

- **Credenciais não vazam em logs**: PAT e session key do Bitwarden não são exibidos em saída de terminal
- **Autenticação via stdin**: PAT passado para `gh auth login` via stdin (não via parâmetro visível em processo)
- **Cleanup automático**: Arquivos temporários (incluindo repo clonado) são removidos após execução

### 🧹 Removido

- **Download via HTTP público**: Não é mais possível baixar instalador de repo público sem autenticação (exceto com `-ForcePublic`)

---

## [1.0.0] - 2025-XX-XX

### ✨ Adicionado

- Instalador universal com detecção de SO
- Suporte completo para Windows Dev Setup
- Seleção de gerenciador de pacotes (Winget, Chocolatey, Scoop)
- Integração com mise para gerenciar SDKs
- Autenticação Git moderna (GitHub CLI, Azure DevOps CLI)
- Interface TUI interativa
- Docker Desktop e WSL2
- One-liner público para instalação rápida

---

## Guia de Migração: v1.x → v2.0

Se você estava usando a versão anterior (v1.x), siga estes passos para migrar:

### Passo 1: Instale Bitwarden CLI

```powershell
winget install Bitwarden.CLI
```

### Passo 2: Faça Login e Desbloqueie

```powershell
bw login
bw unlock
$env:BW_SESSION = "<session-key-retornada>"
```

### Passo 3: Crie GitHub Personal Access Token

1. Acesse: https://github.com/settings/tokens/new
2. Nome: `Dev Setup Token`
3. Scope: **`repo`** (Full control of private repositories)
4. Copie o token gerado

### Passo 4: Armazene o Token no Bitwarden

Via web vault (https://vault.bitwarden.com/):

1. Crie novo item: **`GitHubDevSetup`**
2. Adicione campo customizado:
   - Nome: **`github-pat`**
   - Tipo: **Hidden**
   - Valor: Cole seu PAT

### Passo 5: Execute o Instalador

```powershell
iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.ps1 | iex
```

Agora o instalador irá:
- ✅ Verificar Bitwarden
- ✅ Obter PAT do vault
- ✅ Autenticar no GitHub
- ✅ Clonar repo privado
- ✅ Executar instalação

---

## Roadmap

### v2.1.0 (Planejado)

- [ ] Suporte para Linux Dev Setup (repositório privado `dev-setup-linux`)
- [ ] Suporte para macOS Dev Setup (repositório privado `dev-setup-macos`)
- [ ] Script shell (`install.sh`) com autenticação Bitwarden

### v2.2.0 (Planejado)

- [ ] Cache de credenciais no Windows Credential Manager
- [ ] Suporte a autenticação SSH via Bitwarden
- [ ] Validação de scopes do PAT antes de clonar
- [ ] Modo interativo para criar item no Bitwarden durante instalação

### v3.0.0 (Futuro)

- [ ] Suporte a múltiplos provedores Git (Azure DevOps, GitLab)
- [ ] Sistema de plugins para extensões
- [ ] Configuração via arquivo YAML/JSON
- [ ] Dry-run mode (simulação sem executar)

---

## Convenções de Versionamento

- **MAJOR** (X.0.0): Breaking changes que requerem ação do usuário
- **MINOR** (x.Y.0): Novas funcionalidades compatíveis com versões anteriores
- **PATCH** (x.y.Z): Correções de bugs e pequenas melhorias

---

**Nota:** Para detalhes completos de implementação, veja:
- [README.md](README.md) - Documentação principal
- [TESTING.md](TESTING.md) - Guia de testes
