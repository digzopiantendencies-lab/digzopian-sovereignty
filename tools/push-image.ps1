<#
push-image.ps1
- Logs in to a registry and pushes an image tag.
Usage:
  .\push-image.ps1 -Image searxng:tag -Registry ghcr.io -User myuser -Token $env:GHCR_PAT
#>
param(
    [string]$Image,
    [string]$Registry = "",
    [string]$User = "",
    [string]$Token = ""
)

function Write-Log { param($m) Write-Host "[push] $m" }

if (-not $Image) { Write-Log "Image is required (-Image)."; exit 1 }

if ($Registry -ne "" -and $User -ne "" -and $Token -ne "") {
    Write-Log "Logging in to $Registry..."
    $proc = Start-Process -FilePath docker -ArgumentList "login","$Registry","-u","$User","--password-stdin" -NoNewWindow -PassThru -RedirectStandardInput "pipe"
    $proc.StandardInput.WriteLine($Token)
    $proc.StandardInput.Close()
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) { Write-Log "docker login failed"; exit 1 }
}

Write-Log "Pushing $Image..."
$pushCmd = "docker push $Image"
Invoke-Expression $pushCmd
if ($LASTEXITCODE -ne 0) { Write-Log "Push failed"; exit 1 }
Write-Log "Push complete."