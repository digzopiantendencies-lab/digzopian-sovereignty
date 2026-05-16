param(
    [string]$Url = "http://localhost:8080/",
    [int]$TimeoutSec = 10
)

function Write-Log { param($m) Write-Host "[smoke] $m" }

Write-Log "Testing $Url"
try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec
    if ($r.StatusCode -eq 200) { Write-Log "OK"; exit 0 } else { Write-Log "Status $($r.StatusCode)"; exit 2 }
} catch {
    Write-Log "Failed: $_"; exit 1
}
