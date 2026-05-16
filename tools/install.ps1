<#
install.ps1
-installs/validates prerequisites for building & deploying SearXNG with Docker buildx
#>
Set-StrictMode -Version Latest

function Write-Log {
    param([string]$Message)
    Write-Host "[install] $Message"
}

# Check for admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Please run this script from an elevated PowerShell (Run as Administrator)."
    exit 1
}

Write-Log "Checking for Docker..."
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Log "Docker CLI not found. Please install Docker Desktop: https://www.docker.com/get-started"
    exit 1
}

Write-Log "Checking Docker version..."
try { docker version --format '{{.Server.Version}}' 2>$null | Out-Null } catch { }

# Check buildx
Write-Log "Verifying buildx support..."
$bx = docker buildx version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Log "Docker Buildx not available. Enabling buildx..."
    docker buildx install 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to install buildx automatically. You may need to upgrade Docker Desktop or install buildx manually."
        exit 1
    }
}

# Check if Docker cloud builder (builder instance) exists
Write-Log "Checking for a buildx builder named 'cloud'..."
$builders = docker buildx ls | Out-String
if ($builders -notmatch "\bcloud\b") {
    Write-Log "Creating a new buildx builder 'cloud' using Docker Desktop cloud builder (requires Docker Desktop with cloud builder enabled)."
    docker buildx create --name cloud --use 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to create buildx builder 'cloud'. You may need to enable Docker Desktop cloud builder or create a builder manually."
        exit 1
    }
}

Write-Log "Checking for Git..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Log "Git not found. Installing Git is recommended: https://git-scm.com/download/win"
}

Write-Log "Prerequisites are validated. You can now run the one-click deploy script: .\deploy-searxng.ps1 -ImageName <image> -Tag <tag> -Push -Registry <registry>"
exit 0
