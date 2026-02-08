# GetAllClipIds.ps1
# Fetches all available clips from your Twitch channel and saves them as clipids.json
# Overwrites the file if it already exists in the current directory

$ClientId     = '2bffhn1cp08h0fgaj0eg1jz5fhhebk'
$ClientSecret = 'xi4v8dgkj337sdnub8udtlf6uzj8yo'
$BroadcasterId = '37340689'   # your channel ID

function Get-AccessToken {
    $body = "client_id=$ClientId&client_secret=$ClientSecret&grant_type=client_credentials"
    try {
        $response = Invoke-RestMethod -Method Post `
            -Uri 'https://id.twitch.tv/oauth2/token' `
            -ContentType 'application/x-www-form-urlencoded' `
            -Body $body `
            -ErrorAction Stop
        Write-Host "Access token obtained." -ForegroundColor Green
        return $response.access_token
    }
    catch {
        Write-Host "Failed to get token: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# ────────────────────────────────────────────────
Write-Host "Starting clip fetch for broadcaster $BroadcasterId..." -ForegroundColor Cyan

$AccessToken = Get-AccessToken
$headers = @{
    'Client-Id'     = $ClientId
    'Authorization' = "Bearer $AccessToken"
}

$allClips = @()
$cursor = $null
$maxClips = 1000   # safety cap — adjust if needed

do {
    $uri = "https://api.twitch.tv/helix/clips?broadcaster_id=$BroadcasterId&first=100"
    if ($cursor) { $uri += "&after=$cursor" }

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
        $allClips += $response.data
        $cursor = $response.pagination.cursor
        Write-Host "Fetched $($allClips.Count) clips so far..." -ForegroundColor DarkCyan
    }
    catch {
        Write-Host "Error fetching clips: $($_.Exception.Message)" -ForegroundColor Red
        break
    }
} while ($cursor -and $allClips.Count -lt $maxClips)

if ($allClips.Count -eq 0) {
    Write-Host "No clips found on the channel." -ForegroundColor Yellow
    exit 1
}

Write-Host "Total clips collected: $($allClips.Count)" -ForegroundColor Green

# ────────────────────────────────────────────────
# Build JSON structure
# ────────────────────────────────────────────────
$jsonData = @{
    clips = $allClips | ForEach-Object { $_.id }
} | ConvertTo-Json -Compress

# Save to file in current directory
$jsonFile = "clipids.json"
$jsonData | Out-File -FilePath $jsonFile -Encoding utf8 -Force

Write-Host "`nFile created/overwritten: $jsonFile" -ForegroundColor Green
Write-Host "Location: $(Get-Location)\$jsonFile" -ForegroundColor Cyan

# Optional: show first 5 IDs for verification
Write-Host "`nFirst 5 clip IDs:" -ForegroundColor Yellow
$allClips | Select-Object -ExpandProperty id -First 5 | ForEach-Object { Write-Host "  $_" }

Write-Host "`nDone. You can now upload clipids.json to Google Drive." -ForegroundColor Green