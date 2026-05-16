<#
Deploy-SearXNGOneClick -> deploy-searxng.ps1
Usage:
  .\deploy-searxng.ps1 -ImageName searxng -Tag latest -Push -Registry ghcr.io/yourorg

This script builds SearXNG using Docker Buildx (cloud builder recommended), optionally pushes, and runs a quick smoke test.
#>

param(
    [string]$ImageName = "searxng",
    [string]$Tag = "latest",
    [string]$Registry = "",
    [switch]$Push = $false,
    [switch]$Run = $false,
    [string]$RegistryUser = "",
    [string]$RegistryToken = "",
    [switch]$UseCompose = $false,
    [int]$Port = 8080
)

function Write-Log { param($m) Write-Host "[deploy] $m" }

# Ensure docker exists
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Log "Docker CLI not found. Run tools\install.ps1 first."
    exit 1
}

# Select builder
$builders = docker buildx ls | Out-String
if ($builders -match "\bcloud\b") {
    $builderName = "cloud"
} else {
    $builderName = ($builders -split "\r?\n" | Select-String -Pattern "default" -SimpleMatch).Line -replace ".*\s(\S+)$","$1"
    if (-not $builderName) { $builderName = "default" }
}
Write-Log "Using builder: $builderName"

if ($Registry -ne "") {
    $fullImage = $Registry + "/" + $ImageName + ":" + $Tag
} else {
    $fullImage = $ImageName + ":" + $Tag
}

# Build
Write-Log "Building image $fullImage with buildx on builder $builderName..."
$buildCmd = "docker buildx build --builder $builderName -t $fullImage --platform linux/amd64,linux/arm64 ."
if ($Push) { $buildCmd += " --push" } else { $buildCmd += " --load" }
Write-Log "Running: $buildCmd"
Invoke-Expression $buildCmd
if ($LASTEXITCODE -ne 0) {
    Write-Log "Buildx build failed; will attempt fallback if possible."
    $buildxFailed = $true
} else {
    $buildxFailed = $false
}

if ($Push) { Write-Log "Image pushed: $fullImage" }

# If buildx failed earlier in other runs, provide a fallback to 'docker build' for local single-arch builds
if ($buildxFailed -or (-not $Push -and -not (docker images -q $fullImage 2>$null))) {
    Write-Log "Attempting fallback to 'docker build' for $fullImage..."
    $fallbackCmd = "docker build -t $fullImage ."
    Write-Log "Running: $fallbackCmd"
    Invoke-Expression $fallbackCmd
    if ($LASTEXITCODE -ne 0) { Write-Log "Fallback docker build failed"; exit 1 }
}

# Optional registry login (useful when pushing to GHCR or private registries)
if ($Registry -ne "" -and $RegistryUser -ne "" -and $RegistryToken -ne "") {
    Write-Log "Logging in to $Registry as $RegistryUser..."
    $loginCmd = "docker login $Registry -u $RegistryUser --password-stdin"
    $RegistryToken | docker login $Registry -u $RegistryUser --password-stdin 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Log "Registry login failed"; exit 1 }
}

if ($Run) {
    if ($UseCompose) {
        Write-Log "Using docker-compose for run (tools/docker-compose.yml)..."
        # create LOCAL image reference for compose by tagging
        docker tag $fullImage searxng_local:test 2>$null | Out-Null
        docker-compose -f "$(Join-Path -Path $PSScriptRoot -ChildPath 'docker-compose.yml')" up -d --build
    } else {
        Write-Log "Stopping any existing container named searxng_test..."
        docker rm -f searxng_test 2>$null | Out-Null
        Write-Log "Starting container on port $Port..."
        docker run -d --name searxng_test -p $Port:8080 $fullImage
    }
    Start-Sleep -Seconds 3
    Write-Log "Performing smoke test against http://localhost:$Port/..."
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:$Port/" -UseBasicParsing -TimeoutSec 10
        if ($resp.StatusCode -eq 200) { Write-Log "Smoke test OK" } else { Write-Log "Smoke test returned $($resp.StatusCode)" }
    } catch {
        Write-Log "Smoke test failed: $_"
        exit 1
    }
}

Write-Log "Done."
