$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$charId = "97670833-6531-409d-ae0f-243a820dcdb4"

Write-Host "[PixelLab] Enfileirando animação walking (template) para o novo Daniel Ragnar ($charId)..." -ForegroundColor Cyan

$body = @{
    character_id          = $charId
    template_animation_id = "walking"
    mode                  = "template"
    directions            = @("south", "north", "east", "west")
    animation_name        = "walking"
} | ConvertTo-Json

$res = Invoke-RestMethod -Uri "$BaseUrl/animate-character" -Headers $Headers -Method Post -Body $body
$jobIds = $res.background_job_ids
$groupId = $res.animation_group_id
Write-Host "  -> Animation Group ID: $groupId" -ForegroundColor Yellow
Write-Host "  -> Jobs: $($jobIds -join ', ')" -ForegroundColor Yellow

$attempt = 0
while ($attempt -lt 60) {
    Start-Sleep -Seconds 5
    $attempt++
    $allDone = $true
    foreach ($jid in $jobIds) {
        $jStatus = Invoke-RestMethod -Uri "$BaseUrl/background-jobs/$jid" -Headers $Headers -Method Get
        if ($jStatus.status -ne "completed" -and $jStatus.status -ne "succeeded" -and $jStatus.status -ne "failed") {
            $allDone = $false
        }
    }
    Write-Host "  [$attempt] Verificando conclusão dos 4 jobs de caminhada..." -ForegroundColor Gray
    if ($allDone) { break }
}

$charDetail = Invoke-RestMethod -Uri "$BaseUrl/characters/$charId" -Headers $Headers -Method Get
$charDetail | ConvertTo-Json -Depth 8 | Set-Content -Path "assets/daniel_ragnar/metadata.json"

$anim = $charDetail.animations | Where-Object { $_.animation_group_id -eq $groupId }
if (-not $anim) {
    $anim = $charDetail.animations | Select-Object -Last 1
}

$targetDir = "assets/daniel_ragnar/anim_walk"
Get-ChildItem -Recurse $targetDir -Filter "*.png" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -Recurse $targetDir -Filter "*.import" -ErrorAction SilentlyContinue | Remove-Item -Force

foreach ($d in $anim.directions) {
    $dirName = $d.direction
    $dirFolder = Join-Path $targetDir $dirName
    if (-not (Test-Path $dirFolder)) {
        New-Item -ItemType Directory -Force -Path $dirFolder | Out-Null
    }
    $idx = 0
    foreach ($url in $d.frames) {
        $outPath = Join-Path $dirFolder "$idx.png"
        Invoke-WebRequest -Uri $url -OutFile $outPath
        $idx++
    }
    Write-Host "  [OK] Baixados $idx frames para $dirName" -ForegroundColor Green
}

Write-Host "Animação de caminhada do novo Daniel Ragnar concluída!" -ForegroundColor Green
