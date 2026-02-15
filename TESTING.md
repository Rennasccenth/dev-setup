# Guia de Testes - Autenticação Bitwarden

Este documento descreve os cenários de teste para validar a implementação da autenticação via Bitwarden.

## 🧪 Cenários de Teste

### ✅ Cenário 1: Fluxo Completo com Sucesso

**Pré-requisitos:**
- Bitwarden CLI instalado
- Bitwarden vault desbloqueado (`bw unlock` executado)
- `$env:BW_SESSION` exportado
- Item `GitHubDevSetup` com campo `github-pat` configurado no vault
- GitHub PAT válido com scope `repo`

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ✅ PAT obtido do vault
- ✅ GitHub CLI verificado/instalado
- ✅ Autenticação no GitHub bem-sucedida
- ✅ Repositório privado `rennasccenth/dev-setup-windows` clonado
- ✅ Instalador do Windows executado
- ✅ Cleanup de arquivos temporários

---

### ❌ Cenário 2: Bitwarden Indisponível

**Pré-requisitos:**
- Bitwarden CLI **não instalado** OU vault **bloqueado**

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ❌ Erro: "Bitwarden CLI não está disponível ou desbloqueado"
- Mensagem com instruções de setup
- Exit code: 1

**Validação:**
```powershell
.\install.ps1
echo $LASTEXITCODE  # Deve ser 1
```

---

### ❌ Cenário 3: PAT Não Encontrado no Vault

**Pré-requisitos:**
- Bitwarden CLI instalado e desbloqueado
- Item `GitHubDevSetup` **não existe** no vault OU campo `github-pat` **não configurado**

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ❌ Erro: "GitHub PAT não encontrado no Bitwarden"
- Mensagem com instruções para criar item no vault
- Exit code: 1

---

### ❌ Cenário 4: PAT Inválido/Expirado

**Pré-requisitos:**
- Bitwarden CLI instalado e desbloqueado
- Item `GitHubDevSetup` configurado no vault
- GitHub PAT **inválido** ou **expirado**

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ✅ PAT obtido do vault
- ✅ GitHub CLI verificado/instalado
- ❌ Erro: "Erro ao autenticar no GitHub"
- Mensagem sobre possíveis causas (token inválido/expirado, sem scope 'repo')
- Exit code: 1

---

### ✅ Cenário 5: GitHub CLI Não Instalado

**Pré-requisitos:**
- Bitwarden CLI instalado e desbloqueado
- Item `GitHubDevSetup` com PAT válido
- GitHub CLI **não instalado**
- winget **disponível**

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ✅ PAT obtido do vault
- ✅ GitHub CLI **instalado automaticamente** via winget
- ✅ Autenticação no GitHub bem-sucedida
- ✅ Repositório clonado e instalador executado

---

### ❌ Cenário 6: GitHub CLI Não Instalado + winget Indisponível

**Pré-requisitos:**
- Bitwarden CLI instalado e desbloqueado
- Item `GitHubDevSetup` com PAT válido
- GitHub CLI **não instalado**
- winget **não disponível**

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ✅ PAT obtido do vault
- ❌ Erro: "winget não está disponível"
- Mensagem com instruções para instalação manual
- Exit code: 1

---

### ❌ Cenário 7: PAT Sem Scope 'repo'

**Pré-requisitos:**
- Bitwarden CLI instalado e desbloqueado
- Item `GitHubDevSetup` com PAT válido
- GitHub PAT **sem scope 'repo'** (ex: só com `public_repo`)

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ✅ PAT obtido do vault
- ✅ GitHub CLI verificado/instalado
- ✅ Autenticação no GitHub bem-sucedida
- ❌ Erro ao clonar: "Falha ao clonar repositório privado"
- Mensagem sobre possíveis causas (token sem scope 'repo', repo não existe, etc.)
- Exit code: 1

---

### ❌ Cenário 8: Repositório Privado Não Existe

**Pré-requisitos:**
- Bitwarden CLI instalado e desbloqueado
- Item `GitHubDevSetup` com PAT válido (scope 'repo')
- Repositório `rennasccenth/dev-setup-windows` **não existe** ou usuário **não tem acesso**

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ✅ PAT obtido do vault
- ✅ GitHub CLI verificado/instalado
- ✅ Autenticação no GitHub bem-sucedida
- ❌ Erro ao clonar: "Falha ao clonar repositório privado"
- Exit code: 1

---

### ❌ Cenário 9: Instalador Não Encontrado Após Clone

**Pré-requisitos:**
- Setup completo até clone bem-sucedido
- Repositório clonado **não contém** `install.ps1` na raiz

**Comando:**
```powershell
.\install.ps1
```

**Resultado esperado:**
- ✅ Verificação do Bitwarden bem-sucedida
- ✅ PAT obtido do vault
- ✅ GitHub CLI verificado/instalado
- ✅ Autenticação no GitHub bem-sucedida
- ✅ Repositório clonado
- ❌ Erro: "Instalador não encontrado no repositório clonado"
- Path esperado exibido
- Cleanup de arquivos temporários
- Exit code: 1

---

### ✅ Cenário 10: Modo Público (ForcePublic)

**Pré-requisitos:**
- Nenhum (Bitwarden não é necessário)

**Comando:**
```powershell
.\install.ps1 -ForcePublic
```

**Resultado esperado:**
- ⚠️  Mensagem: "Modo público: pulando autenticação"
- Tentativa de download do instalador via URL pública
- Se repo público existe: ✅ Instalador executado
- Se repo é privado: ❌ Erro HTTP 404

---

### ✅ Cenário 11: PAT Via Parâmetro (Testing)

**Pré-requisitos:**
- GitHub CLI instalado
- PAT válido fornecido via parâmetro

**Comando:**
```powershell
.\install.ps1 -GitHubPAT "ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

**Resultado esperado:**
- Mensagem: "Usando GitHub PAT fornecido via parâmetro"
- **Não consulta** Bitwarden
- Autenticação e clone bem-sucedidos

---

### ✅ Cenário 12: Parâmetros Passados ao Instalador

**Pré-requisitos:**
- Setup completo e funcional

**Comando:**
```powershell
.\install.ps1 -SkipDotnet -NoPrompt
```

**Resultado esperado:**
- Fluxo completo executado
- Parâmetros `-SkipDotnet` e `-NoPrompt` **repassados** ao instalador do Windows
- Instalador do Windows executa com esses parâmetros

---

## 🔍 Validações de Segurança

### 1. PAT Não Deve Aparecer em Logs

```powershell
.\install.ps1 *> test-output.log
Get-Content test-output.log | Select-String "ghp_"
# Resultado esperado: nenhuma linha com o PAT
```

### 2. Session Key do Bitwarden Não Deve Vazar

```powershell
.\install.ps1 *> test-output.log
Get-Content test-output.log | Select-String "BW_SESSION"
# Resultado esperado: nenhuma linha com a session key
```

### 3. Cleanup de Arquivos Temporários

```powershell
# Antes
$tempCountBefore = (Get-ChildItem $env:TEMP | Where-Object { $_.Name -like "dev-setup-*" }).Count

# Executar
.\install.ps1

# Depois
$tempCountAfter = (Get-ChildItem $env:TEMP | Where-Object { $_.Name -like "dev-setup-*" }).Count

# Validar
$tempCountAfter -le $tempCountBefore  # Deve ser TRUE
```

---

## 📊 Checklist de Testes

Marque os cenários testados:

- [ ] ✅ Cenário 1: Fluxo completo com sucesso
- [ ] ❌ Cenário 2: Bitwarden indisponível
- [ ] ❌ Cenário 3: PAT não encontrado no vault
- [ ] ❌ Cenário 4: PAT inválido/expirado
- [ ] ✅ Cenário 5: GitHub CLI não instalado (auto-install)
- [ ] ❌ Cenário 6: GitHub CLI não instalado + winget indisponível
- [ ] ❌ Cenário 7: PAT sem scope 'repo'
- [ ] ❌ Cenário 8: Repositório privado não existe
- [ ] ❌ Cenário 9: Instalador não encontrado após clone
- [ ] ✅ Cenário 10: Modo público (ForcePublic)
- [ ] ✅ Cenário 11: PAT via parâmetro
- [ ] ✅ Cenário 12: Parâmetros passados ao instalador
- [ ] 🔍 Validação: PAT não aparece em logs
- [ ] 🔍 Validação: Session key não vaza
- [ ] 🔍 Validação: Cleanup de temp files

---

## 🛠️ Comandos Úteis para Setup de Teste

### Criar Item de Teste no Bitwarden

```powershell
# PowerShell - criar item com PAT de teste
$item = bw get template item | ConvertFrom-Json
$item.name = "GitHubDevSetup"
$item.type = 2
$field = @{
    name = "github-pat"
    value = "ghp_TESTTOKEN123456789"  # Substitua com PAT real
    type = 1
}
$item.fields = @($field)
$item | ConvertTo-Json | bw encode | bw create item
```

### Deletar Item de Teste

```powershell
# Obter ID do item
$itemId = (bw list items --search "GitHubDevSetup" | ConvertFrom-Json)[0].id

# Deletar item
bw delete item $itemId
```

### Simular Bitwarden Bloqueado

```powershell
# Bloquear vault
bw lock

# Remover session
Remove-Item env:BW_SESSION
```

### Simular GitHub CLI Não Instalado

```powershell
# Desinstalar gh
winget uninstall GitHub.cli

# Verificar
Get-Command gh -ErrorAction SilentlyContinue  # Deve retornar null
```

---

## 📝 Notas

- Todos os testes devem ser executados em um ambiente **limpo** (sem cache de autenticação GitHub)
- Para testar autenticação, limpe credenciais do GitHub CLI: `gh auth logout`
- Para testar clonagem, limpe cache de repos: `Remove-Item $env:TEMP\dev-setup-* -Recurse -Force`
- Testes que modificam estado global (instalação de software) devem ser executados em **máquina virtual** ou **container**
