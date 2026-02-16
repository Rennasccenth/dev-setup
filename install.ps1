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

function Wait-UserPrompt {
    <#
    .SYNOPSIS
    Aguarda input do usuário antes de fechar a janela
    #>
    param(
        [switch]$NoPrompt
    )

    # Pular se NoPrompt ativado
    if ($NoPrompt) { return }

    # Pular se em ambiente CI/CD
    if ($env:CI -or $env:TF_BUILD -or $env:GITHUB_ACTIONS) { return }

    # Pular se não for interativo
    if (-not [Environment]::UserInteractive) { return }

    Write-Host ""
    Write-Host "Pressione qualquer tecla para fechar esta janela..." -ForegroundColor Cyan

    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        # Fallback se RawUI não disponível
        try {
            $null = Read-Host "Pressione ENTER para continuar"
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
}

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
        Wait-UserPrompt
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
        Wait-UserPrompt
        exit 1
    }

    try {
        # Install without masking output
        winget install GitHub.cli --silent --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao instalar GitHub CLI (exit code: $LASTEXITCODE)"
        }

        # Wait for Windows to register the installation
        Write-Host "⏳ Aguardando registro da instalação..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3

        # Try to find gh with retry (up to 5 attempts)
        $maxRetries = 5
        $retryCount = 0
        $ghFound = $false

        while (-not $ghFound -and $retryCount -lt $maxRetries) {
            # Force PATH refresh
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path", "User")

            # Try to find gh
            $ghCommand = Get-Command gh -ErrorAction SilentlyContinue

            if ($ghCommand) {
                $ghFound = $true
                Write-Host "✓ GitHub CLI detectado: $($ghCommand.Source)" -ForegroundColor Green
            } else {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "⏳ Tentativa $retryCount/$maxRetries - aguardando..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
        }

        # Fallback: check common paths manually
        if (-not $ghFound) {
            Write-Host "⏳ Verificando paths comuns..." -ForegroundColor Yellow
            $commonPaths = @(
                "$env:ProgramFiles\GitHub CLI\gh.exe",
                "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe",
                "${env:ProgramFiles(x86)}\GitHub CLI\gh.exe"
            )

            foreach ($path in $commonPaths) {
                if (Test-Path $path) {
                    Write-Host "✓ GitHub CLI encontrado em: $path" -ForegroundColor Green
                    # Add to current session PATH
                    $env:Path = "$([System.IO.Path]::GetDirectoryName($path));$env:Path"
                    $ghFound = $true
                    break
                }
            }
        }

        if (-not $ghFound) {
            throw "GitHub CLI instalado mas não encontrado no PATH. Tente reiniciar o terminal."
        }

        Write-Host "✓ GitHub CLI instalado com sucesso" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao instalar GitHub CLI: $_" -ForegroundColor Red
        Wait-UserPrompt
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

        # Check if error is command not found
        if ($_ -match "gh.*not found|gh.*não.*encontrado|cannot find.*gh|CommandNotFoundException") {
            Write-Host "Causa detectada:" -ForegroundColor Yellow
            Write-Host "• GitHub CLI (gh) não está no PATH" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Solução:" -ForegroundColor Yellow
            Write-Host "Reinicie o terminal ou PowerShell para atualizar o PATH" -ForegroundColor Blue
        } else {
            Write-Host "Possíveis causas:" -ForegroundColor Yellow
            Write-Host "• Token inválido ou expirado" -ForegroundColor Cyan
            Write-Host "• Token sem scope 'repo'" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Crie um novo token em: https://github.com/settings/tokens/new" -ForegroundColor Blue
            Write-Host "Scopes necessários: repo (Full control of private repositories)" -ForegroundColor Blue
        }

        Wait-UserPrompt
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

        Wait-UserPrompt
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
        Wait-UserPrompt
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
# Check Bitwarden availability (REQUIRED)
Write-Host "🔍 Verificando Bitwarden CLI..." -ForegroundColor Cyan

if (-not (Test-BitwardenAvailable)) {
    Write-Host "❌ Bitwarden CLI não está disponível ou desbloqueado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitwarden CLI é obrigatório para acessar repositórios privados." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Setup necessário:" -ForegroundColor Yellow
    Write-Host "1. Instale: " -ForegroundColor Cyan -NoNewline
    Write-Host "winget install Bitwarden.CLI --source winget" -ForegroundColor Blue
    Write-Host "2. Login: " -ForegroundColor Cyan -NoNewline
    Write-Host "bw login" -ForegroundColor Blue
    Write-Host "3. Unlock: " -ForegroundColor Cyan -NoNewline
    Write-Host "bw unlock" -ForegroundColor Blue
    Write-Host "4. Export session: " -ForegroundColor Cyan -NoNewline
    Write-Host "`$env:BW_SESSION = '<session-key>'" -ForegroundColor Blue
    Wait-UserPrompt
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
        Wait-UserPrompt
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

# Verify that gh is actually available before continuing
Write-Host "🔍 Verificando GitHub CLI..." -ForegroundColor Cyan
$ghCommand = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghCommand) {
    Write-Host "❌ GitHub CLI não está disponível" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possíveis soluções:" -ForegroundColor Yellow
    Write-Host "1. Reinstale manualmente: " -ForegroundColor Cyan -NoNewline
    Write-Host "winget install GitHub.cli" -ForegroundColor Blue
    Write-Host "2. Reinicie o terminal/PowerShell" -ForegroundColor Cyan
    Write-Host "3. Adicione manualmente ao PATH" -ForegroundColor Cyan
    Wait-UserPrompt
    exit 1
}

Write-Host "✓ GitHub CLI disponível: $($ghCommand.Source)" -ForegroundColor Green
Write-Host ""

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
    Wait-UserPrompt
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

    Wait-UserPrompt
    exit 1
}

# Cleanup
Write-Host ""
Write-Host "🧹 Limpando arquivos temporários..." -ForegroundColor Cyan
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Limpeza concluída" -ForegroundColor Green

# Aguardar input antes de fechar (a menos que automatizado)
Wait-UserPrompt -NoPrompt:$NoPrompt

# Exit with installer's exit code
exit $installerExitCode
