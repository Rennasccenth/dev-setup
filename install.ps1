# dev-setup - OS Router with Bitwarden Authentication
# Clones private OS-specific repositories after authenticating via Bitwarden
# Usage: iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.ps1 | iex

param(
    [switch]$SkipDotnet,
    [switch]$NoPrompt,
    [string]$GitHubPAT = "",      # Pass PAT directly (for testing)
    [switch]$ForcePublic          # Skip authentication (for public repos)
)

$ErrorActionPreference = "Stop"

# ============================================================================
# AUXILIARY FUNCTIONS
# ============================================================================

function Test-BitwardenAvailable {
    <#
    .SYNOPSIS
    Checks if Bitwarden CLI is available and unlocked
    #>
    try {
        $bwPath = Get-Command bw -ErrorAction SilentlyContinue
        if (-not $bwPath) {
            return $false
        }

        $status = bw status | ConvertFrom-Json
        return $status.status -eq "unlocked"
    } catch {
        return $false
    }
}

function Get-BitwardenSecret {
    <#
    .SYNOPSIS
    Retrieves a secret field from a Bitwarden vault item
    #>
    param(
        [string]$ItemName,
        [string]$FieldName
    )

    try {
        $item = bw get item $ItemName | ConvertFrom-Json

        $field = $item.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1

        if ($null -eq $field) {
            return $null
        }

        return $field.value
    } catch {
        Write-Host "⚠️  Erro ao obter segredo do Bitwarden: $_" -ForegroundColor Yellow
        return $null
    }
}

function Install-GitHubCLI {
    <#
    .SYNOPSIS
    Installs GitHub CLI via winget if not already installed
    #>
    Write-Host "📦 Instalando GitHub CLI..." -ForegroundColor Cyan

    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetPath) {
        Write-Host "❌ winget não está disponível" -ForegroundColor Red
        Write-Host "Instale manualmente: https://github.com/cli/cli#installation" -ForegroundColor Yellow
        exit 1
    }

    try {
        winget install GitHub.cli --silent --accept-package-agreements --accept-source-agreements | Out-Null

        # Refresh PATH to include newly installed gh
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        Write-Host "✓ GitHub CLI instalado com sucesso" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao instalar GitHub CLI: $_" -ForegroundColor Red
        exit 1
    }
}

function Set-GitHubAuthentication {
    <#
    .SYNOPSIS
    Authenticates with GitHub using a Personal Access Token
    #>
    param(
        [string]$PAT
    )

    Write-Host "🔐 Autenticando no GitHub..." -ForegroundColor Cyan

    try {
        # Authenticate using PAT via stdin
        $PAT | gh auth login --with-token

        if ($LASTEXITCODE -ne 0) {
            throw "gh auth login falhou com código $LASTEXITCODE"
        }

        # Verify authentication
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Falha na verificação de autenticação"
        }

        Write-Host "✓ Autenticado no GitHub com sucesso" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao autenticar no GitHub" -ForegroundColor Red
        Write-Host "Detalhes: $_" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possíveis causas:" -ForegroundColor Yellow
        Write-Host "• Token inválido ou expirado" -ForegroundColor Cyan
        Write-Host "• Token sem scope 'repo'" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Crie um novo token em: https://github.com/settings/tokens/new" -ForegroundColor Blue
        Write-Host "Scopes necessários: repo (Full control of private repositories)" -ForegroundColor Blue
        exit 1
    }
}

function Get-PrivateOSRepository {
    <#
    .SYNOPSIS
    Clones the private OS-specific repository
    #>
    param(
        [string]$OS,
        [string]$DestinationPath
    )

    # Map OS to private repository
    $OsRepoMap = @{
        "Windows" = "rennasccenth/dev-setup-windows"
        "Linux"   = "rennasccenth/dev-setup-linux"   # Future
        "macOS"   = "rennasccenth/dev-setup-macos"   # Future
    }

    $repo = $OsRepoMap[$OS]

    if ([string]::IsNullOrWhiteSpace($repo)) {
        Write-Host "❌ Sistema operacional '$OS' não suportado ainda" -ForegroundColor Red
        Write-Host "Repositórios disponíveis:" -ForegroundColor Yellow
        $OsRepoMap.Keys | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Cyan
        }
        exit 1
    }

    Write-Host "📦 Clonando repositório privado: $repo..." -ForegroundColor Cyan

    try {
        # Clone using gh CLI (authenticated)
        gh repo clone $repo $DestinationPath -- --quiet

        if ($LASTEXITCODE -ne 0) {
            throw "gh repo clone falhou com código $LASTEXITCODE"
        }

        Write-Host "✓ Repositório clonado com sucesso" -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao clonar repositório privado" -ForegroundColor Red
        Write-Host "Detalhes: $_" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possíveis causas:" -ForegroundColor Yellow
        Write-Host "• Token sem scope 'repo'" -ForegroundColor Cyan
        Write-Host "• Repositório não existe ou você não tem acesso" -ForegroundColor Cyan
        Write-Host "• Problemas de conexão de rede" -ForegroundColor Cyan
        exit 1
    }
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

Write-Host "🚀 Dev Setup - Universal Installer" -ForegroundColor Cyan
Write-Host ""

# Detect OS
if (-not $IsWindows -and -not $env:OS -eq "Windows_NT") {
    Write-Host "❌ Este script PowerShell é para Windows" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para Linux/macOS, use:" -ForegroundColor Yellow
    Write-Host "curl -fsSL https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.sh | bash" -ForegroundColor Blue
    exit 1
}

Write-Host "✓ Sistema operacional: Windows" -ForegroundColor Green
Write-Host ""

# Skip authentication if ForcePublic flag is set
if ($ForcePublic) {
    Write-Host "⚠️  Modo público: pulando autenticação" -ForegroundColor Yellow
    Write-Host ""

    # Fallback to public URL (if repo is public)
    $windowsInstallerUrl = "https://raw.githubusercontent.com/rennasccenth/dev-setup/main/windows-dev-setup/install.ps1"

    try {
        $installerArgs = @()
        if ($SkipDotnet) { $installerArgs += "-SkipDotnet" }
        if ($NoPrompt) { $installerArgs += "-NoPrompt" }

        $installerScript = Invoke-WebRequest -Uri $windowsInstallerUrl -UseBasicParsing | Select-Object -ExpandProperty Content
        $scriptBlock = [ScriptBlock]::Create($installerScript)

        if ($installerArgs.Count -gt 0) {
            & $scriptBlock @installerArgs
        } else {
            & $scriptBlock
        }
        exit 0
    } catch {
        Write-Host "❌ Erro ao baixar instalador público: $_" -ForegroundColor Red
        exit 1
    }
}

# Check Bitwarden availability (REQUIRED)
Write-Host "🔍 Verificando Bitwarden CLI..." -ForegroundColor Cyan

if (-not (Test-BitwardenAvailable)) {
    Write-Host "❌ Bitwarden CLI não está disponível ou desbloqueado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitwarden CLI é obrigatório para acessar repositórios privados." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Setup necessário:" -ForegroundColor Yellow
    Write-Host "1. Instale: " -ForegroundColor Cyan -NoNewline
    Write-Host "winget install Bitwarden.CLI" -ForegroundColor Blue
    Write-Host "2. Login: " -ForegroundColor Cyan -NoNewline
    Write-Host "bw login" -ForegroundColor Blue
    Write-Host "3. Unlock: " -ForegroundColor Cyan -NoNewline
    Write-Host "bw unlock" -ForegroundColor Blue
    Write-Host "4. Export session: " -ForegroundColor Cyan -NoNewline
    Write-Host "`$env:BW_SESSION = '<session-key>'" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Documentação: https://github.com/rennasccenth/dev-setup#setup-inicial" -ForegroundColor Blue
    exit 1
}

Write-Host "✓ Bitwarden CLI disponível e desbloqueado" -ForegroundColor Green
Write-Host ""

# Get GitHub PAT from Bitwarden (or use provided PAT)
if ([string]::IsNullOrWhiteSpace($GitHubPAT)) {
    Write-Host "🔑 Obtendo GitHub PAT do Bitwarden..." -ForegroundColor Cyan

    $GitHubPAT = Get-BitwardenSecret "GitHubDevSetup" "github-pat"

    if ([string]::IsNullOrWhiteSpace($GitHubPAT)) {
        Write-Host "❌ GitHub PAT não encontrado no Bitwarden" -ForegroundColor Red
        Write-Host ""
        Write-Host "Crie um item no Bitwarden vault:" -ForegroundColor Yellow
        Write-Host "• Nome: " -ForegroundColor Cyan -NoNewline
        Write-Host "GitHubDevSetup" -ForegroundColor Blue
        Write-Host "• Campo customizado: " -ForegroundColor Cyan -NoNewline
        Write-Host "github-pat" -ForegroundColor Blue -NoNewline
        Write-Host " (tipo: Hidden)" -ForegroundColor Cyan
        Write-Host "• Valor: Seu GitHub Personal Access Token" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Criar token: https://github.com/settings/tokens/new" -ForegroundColor Blue
        Write-Host "Scopes necessários: repo (Full control of private repositories)" -ForegroundColor Blue
        exit 1
    }

    Write-Host "✓ GitHub PAT obtido com sucesso" -ForegroundColor Green
} else {
    Write-Host "✓ Usando GitHub PAT fornecido via parâmetro" -ForegroundColor Green
}

Write-Host ""

# Install/verify GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Install-GitHubCLI
    Write-Host ""
}

# Authenticate with GitHub
Set-GitHubAuthentication -PAT $GitHubPAT
Write-Host ""

# Clone private OS repository
$tempDir = "$env:TEMP\dev-setup-$(Get-Random)"
Get-PrivateOSRepository -OS "Windows" -DestinationPath $tempDir
Write-Host ""

# Execute OS-specific installer
$installerPath = Join-Path $tempDir "install.ps1"

if (-not (Test-Path $installerPath)) {
    Write-Host "❌ Instalador não encontrado no repositório clonado" -ForegroundColor Red
    Write-Host "Path esperado: $installerPath" -ForegroundColor Yellow
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "🚀 Executando instalador do Windows..." -ForegroundColor Cyan
Write-Host ""

try {
    # Build arguments for installer
    $installerArgs = @()
    if ($SkipDotnet) { $installerArgs += "-SkipDotnet" }
    if ($NoPrompt) { $installerArgs += "-NoPrompt" }

    # Execute installer
    if ($installerArgs.Count -gt 0) {
        & $installerPath @installerArgs
    } else {
        & $installerPath
    }

    $installerExitCode = $LASTEXITCODE
} catch {
    Write-Host "❌ Erro ao executar instalador: $_" -ForegroundColor Red
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Cleanup
Write-Host ""
Write-Host "🧹 Limpando arquivos temporários..." -ForegroundColor Cyan
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Limpeza concluída" -ForegroundColor Green

# Exit with installer's exit code
exit $installerExitCode
