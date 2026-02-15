# dev-setup - OS Router (PowerShell)
# Redireciona para o instalador Windows
# Uso: iwr -useb https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.ps1 | iex

param(
    [switch]$SkipDotnet,
    [switch]$NoPrompt
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Dev Setup - Universal Installer" -ForegroundColor Cyan
Write-Host ""

# Detectar se está rodando no Windows
if (-not $IsWindows -and -not $env:OS -eq "Windows_NT") {
    Write-Host "❌ Este script PowerShell é para Windows" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para Linux/macOS, use:" -ForegroundColor Yellow
    Write-Host "curl -fsSL https://raw.githubusercontent.com/rennasccenth/dev-setup/main/install.sh | bash" -ForegroundColor Blue
    exit 1
}

Write-Host "✓ Sistema operacional: Windows" -ForegroundColor Green
Write-Host ""

# Redirecionar para o instalador Windows
Write-Host "➜ Redirecionando para o instalador do Windows Dev Setup..." -ForegroundColor Cyan
Write-Host ""

# Baixar e executar o instalador do Windows
$windowsInstallerUrl = "https://raw.githubusercontent.com/rennasccenth/dev-setup/main/windows-dev-setup/install.ps1"

try {
    # Criar argumentos para passar ao instalador
    $installerArgs = @()
    if ($SkipDotnet) { $installerArgs += "-SkipDotnet" }
    if ($NoPrompt) { $installerArgs += "-NoPrompt" }

    # Baixar e executar o script
    $installerScript = Invoke-WebRequest -Uri $windowsInstallerUrl -UseBasicParsing | Select-Object -ExpandProperty Content

    # Executar o script baixado com os parâmetros
    $scriptBlock = [ScriptBlock]::Create($installerScript)

    if ($installerArgs.Count -gt 0) {
        & $scriptBlock @installerArgs
    } else {
        & $scriptBlock
    }
} catch {
    Write-Host ""
    Write-Host "❌ Erro ao baixar ou executar o instalador do Windows" -ForegroundColor Red
    Write-Host "Detalhes: $_" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tente executar diretamente:" -ForegroundColor Yellow
    Write-Host "iwr -useb $windowsInstallerUrl | iex" -ForegroundColor Blue
    exit 1
}
