# Dev Setup - Validação de Setup
# Verifica se todos os requisitos para o instalador estão configurados corretamente

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "🔍 Dev Setup - Validação de Requisitos" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allChecksPassed = $true

# ============================================================================
# 1. Verificar Bitwarden CLI
# ============================================================================

Write-Host "[1/5] Verificando Bitwarden CLI..." -ForegroundColor Yellow

$bwPath = Get-Command bw -ErrorAction SilentlyContinue

if (-not $bwPath) {
    Write-Host "  ❌ FALHOU: Bitwarden CLI não está instalado" -ForegroundColor Red
    Write-Host "  → Solução: winget install Bitwarden.CLI" -ForegroundColor Cyan
    $allChecksPassed = $false
} else {
    Write-Host "  ✓ Bitwarden CLI instalado: $($bwPath.Source)" -ForegroundColor Green

    if ($Verbose) {
        $bwVersion = bw --version
        Write-Host "    Versão: $bwVersion" -ForegroundColor DarkGray
    }
}

Write-Host ""

# ============================================================================
# 2. Verificar Status do Bitwarden
# ============================================================================

Write-Host "[2/5] Verificando status do Bitwarden..." -ForegroundColor Yellow

if ($bwPath) {
    try {
        $status = bw status | ConvertFrom-Json

        if ($status.status -eq "unlocked") {
            Write-Host "  ✓ Bitwarden vault está desbloqueado" -ForegroundColor Green

            if ($Verbose) {
                Write-Host "    Status: $($status.status)" -ForegroundColor DarkGray
                Write-Host "    User: $($status.userEmail)" -ForegroundColor DarkGray
            }
        } elseif ($status.status -eq "locked") {
            Write-Host "  ❌ FALHOU: Bitwarden vault está bloqueado" -ForegroundColor Red
            Write-Host "  → Solução: bw unlock" -ForegroundColor Cyan
            Write-Host "  → Depois: `$env:BW_SESSION = '<session-key>'" -ForegroundColor Cyan
            $allChecksPassed = $false
        } elseif ($status.status -eq "unauthenticated") {
            Write-Host "  ❌ FALHOU: Bitwarden não está autenticado" -ForegroundColor Red
            Write-Host "  → Solução: bw login" -ForegroundColor Cyan
            $allChecksPassed = $false
        } else {
            Write-Host "  ⚠️  AVISO: Status desconhecido: $($status.status)" -ForegroundColor Yellow
            $allChecksPassed = $false
        }
    } catch {
        Write-Host "  ❌ FALHOU: Erro ao verificar status do Bitwarden" -ForegroundColor Red
        Write-Host "  Erro: $_" -ForegroundColor DarkRed
        $allChecksPassed = $false
    }
}

Write-Host ""

# ============================================================================
# 3. Verificar Item GitHubDevSetup no Vault
# ============================================================================

Write-Host "[3/5] Verificando item 'GitHubDevSetup' no vault..." -ForegroundColor Yellow

if ($bwPath -and $status.status -eq "unlocked") {
    try {
        $item = bw get item "GitHubDevSetup" 2>$null | ConvertFrom-Json

        if ($item) {
            Write-Host "  ✓ Item 'GitHubDevSetup' encontrado" -ForegroundColor Green

            if ($Verbose) {
                Write-Host "    ID: $($item.id)" -ForegroundColor DarkGray
                Write-Host "    Nome: $($item.name)" -ForegroundColor DarkGray
                Write-Host "    Tipo: $($item.type)" -ForegroundColor DarkGray
            }

            # Verificar campo github-pat
            $patField = $item.fields | Where-Object { $_.name -eq "github-pat" } | Select-Object -First 1

            if ($patField) {
                Write-Host "  ✓ Campo 'github-pat' encontrado" -ForegroundColor Green

                if ($Verbose) {
                    $patLength = $patField.value.Length
                    $patMasked = $patField.value.Substring(0, [Math]::Min(7, $patLength)) + "*" * [Math]::Max(0, $patLength - 7)
                    Write-Host "    Tipo do campo: $($patField.type)" -ForegroundColor DarkGray
                    Write-Host "    Valor (mascarado): $patMasked" -ForegroundColor DarkGray
                }

                # Validar formato do PAT
                if ($patField.value -match "^ghp_[a-zA-Z0-9]{36}$") {
                    Write-Host "  ✓ Formato do PAT parece válido (ghp_...)" -ForegroundColor Green
                } elseif ($patField.value -match "^github_pat_[a-zA-Z0-9_]+$") {
                    Write-Host "  ✓ Formato do PAT parece válido (github_pat_...)" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠️  AVISO: Formato do PAT não reconhecido" -ForegroundColor Yellow
                    Write-Host "  → Tokens GitHub geralmente começam com 'ghp_' ou 'github_pat_'" -ForegroundColor Cyan
                }
            } else {
                Write-Host "  ❌ FALHOU: Campo 'github-pat' não encontrado" -ForegroundColor Red
                Write-Host "  → Solução: Adicione campo customizado 'github-pat' ao item" -ForegroundColor Cyan
                $allChecksPassed = $false
            }
        } else {
            Write-Host "  ❌ FALHOU: Item 'GitHubDevSetup' não encontrado no vault" -ForegroundColor Red
            Write-Host "  → Solução: Crie item 'GitHubDevSetup' no vault" -ForegroundColor Cyan
            $allChecksPassed = $false
        }
    } catch {
        Write-Host "  ❌ FALHOU: Erro ao buscar item no vault" -ForegroundColor Red
        Write-Host "  Erro: $_" -ForegroundColor DarkRed
        $allChecksPassed = $false
    }
} else {
    Write-Host "  ⏭️  PULADO: Bitwarden não está disponível/desbloqueado" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================================================
# 4. Verificar GitHub CLI
# ============================================================================

Write-Host "[4/5] Verificando GitHub CLI..." -ForegroundColor Yellow

$ghPath = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghPath) {
    Write-Host "  ⚠️  AVISO: GitHub CLI não está instalado" -ForegroundColor Yellow
    Write-Host "  → O instalador pode instalar automaticamente" -ForegroundColor Cyan
    Write-Host "  → Ou instale manualmente: winget install GitHub.cli" -ForegroundColor Cyan
} else {
    Write-Host "  ✓ GitHub CLI instalado: $($ghPath.Source)" -ForegroundColor Green

    if ($Verbose) {
        $ghVersion = gh --version | Select-Object -First 1
        Write-Host "    Versão: $ghVersion" -ForegroundColor DarkGray
    }

    # Verificar se já está autenticado
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Já autenticado no GitHub" -ForegroundColor Green

        if ($Verbose) {
            Write-Host "    $authStatus" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  ℹ️  INFO: Não autenticado ainda (será autenticado pelo instalador)" -ForegroundColor Cyan
    }
}

Write-Host ""

# ============================================================================
# 5. Verificar winget
# ============================================================================

Write-Host "[5/5] Verificando winget..." -ForegroundColor Yellow

$wingetPath = Get-Command winget -ErrorAction SilentlyContinue

if (-not $wingetPath) {
    Write-Host "  ⚠️  AVISO: winget não está disponível" -ForegroundColor Yellow
    Write-Host "  → Necessário para instalação automática do GitHub CLI" -ForegroundColor Cyan
    Write-Host "  → Instale via Microsoft Store: 'App Installer'" -ForegroundColor Cyan
} else {
    Write-Host "  ✓ winget disponível: $($wingetPath.Source)" -ForegroundColor Green

    if ($Verbose) {
        $wingetVersion = winget --version
        Write-Host "    Versão: $wingetVersion" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================================
# Resumo Final
# ============================================================================

Write-Host ""

if ($allChecksPassed) {
    Write-Host "✅ SUCESSO: Todos os requisitos obrigatórios estão configurados!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Você está pronto para executar o instalador:" -ForegroundColor Cyan
    Write-Host "  iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.ps1 | iex" -ForegroundColor Blue
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ FALHOU: Alguns requisitos obrigatórios não estão configurados" -ForegroundColor Red
    Write-Host ""
    Write-Host "Siga as soluções indicadas acima e execute este script novamente." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para ajuda completa, consulte:" -ForegroundColor Cyan
    Write-Host "  https://github.com/rennasccenth/dev-setup#setup-inicial" -ForegroundColor Blue
    Write-Host ""
    exit 1
}
