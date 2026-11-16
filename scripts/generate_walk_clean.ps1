$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$CharId = "e3cc8aa7-f696-453f-b3d9-3809e52692d3"
$GroupId = "e9194d2e-e8ee-49cd-96f9-ae2a18b51eed"
$FirstJobId = "df8aedc9-f2d2-460e-8e49-f86f3ac360f6"

function Wait-Job {
    param([string]$JobId)
    $maxAttempts = 50
    $attempt = 0
    Write-Host "Aguardando job $JobId..." -ForegroundColor Yellow
    while ($attempt -lt $maxAttempts) {
        Start-Sleep -Seconds 5
        $attempt++
        $status = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/background-jobs/$JobId" -Headers $Headers -Method Get
        Write-Host "  [$attempt] Status: $($status.status)" -ForegroundColor Gray
        if ($status.status -eq "completed" -or $status.status -eq "succeeded") {
            return $true
        }
        if ($status.status -eq "failed") {
            Write-Error "Job falhou: $($status.error)"
            return $false
        }
    }
    return $false
}

# 1. Aguardar South que já está rodando
Write-Host "--- Passo 1: Aguardando conclusão da direção SOUTH ---" -ForegroundColor Cyan
$southOk = Wait-Job -JobId $FirstJobId

# 2. Gerar as outras 3 direções sequencialmente
$remainingDirections = @("north", "east", "west")

foreach ($dir in $remainingDirections) {
    Write-Host "--- Disparando direção: $dir ---" -ForegroundColor Cyan
    $body = @{
        character_id = $CharId
        animation_group_id = $GroupId
        template_animation_id = "walking"
        mode = "template"
        directions = @($dir)
    } | ConvertTo-Json

    $postRes = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/animate-character" -Headers $Headers -Method Post -Body $body
    $newJobId = $postRes.background_job_ids[0]
    Write-Host "Job disparado para $($dir): $newJobId" -ForegroundColor Green
    
    $ok = Wait-Job -JobId $newJobId
    if (-not $ok) {
        Write-Warning "Falha ao gerar $dir"
    }
}

Write-Host "Todas as 4 direções concluídas! Baixando assets melhorados..." -ForegroundColor Green

# 3. Baixar detalhes da animação do personagem
$charDetail = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/characters/$CharId" -Headers $Headers -Method Get

$targetBase = "assets/daniel_ragnar/anim_walk_improved"
if (-not (Test-Path $targetBase)) {
    New-Item -ItemType Directory -Force -Path $targetBase | Out-Null
}

$charDetail | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $targetBase "char_full.json")

# Encontrar a animação do nosso group_id
$ourAnim = $charDetail.animations | Where-Object { $_.animation_group_id -eq $GroupId }
if ($ourAnim) {
    Write-Host "Encontrada animação $GroupId com $($ourAnim.directions.Count) direções." -ForegroundColor Cyan
    foreach ($d in $ourAnim.directions) {
        $dirName = $d.direction
        $dirFolder = Join-Path $targetBase $dirName
        if (-not (Test-Path $dirFolder)) { New-Item -ItemType Directory -Force -Path $dirFolder | Out-Null }
        
        Write-Host "Baixando frames para $dirName ($($d.frames.Count) frames)..." -ForegroundColor Yellow
        $fIdx = 0
        foreach ($f in $d.frames) {
            $frameUrl = $f.url
            $outPng = Join-Path $dirFolder "$fIdx.png"
            Invoke-WebRequest -Uri $frameUrl -OutFile $outPng
            $fIdx++
        }
        Write-Host "Direção $dirName salva com sucesso!" -ForegroundColor Green
    }
} else {
    Write-Warning "Grupo $GroupId não encontrado diretamente na lista de animações do personagem."
}

Write-Host "Concluído com sucesso!" -ForegroundColor Green
