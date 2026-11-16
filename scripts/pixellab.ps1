param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "balance",
    [string]$Prompt = "",
    [string]$Name = "asset",
    [int]$Size = 48,
    [string]$OutputDir = "assets",
    [string]$CharId = "",
    [string]$TemplateAnimation = "walking",
    [string]$Mode = "template"
)

$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

function Get-Balance {
    Write-Host "[PixelLab] Consultando saldo da conta..." -ForegroundColor Cyan
    try {
        $res = Invoke-RestMethod -Uri "$BaseUrl/balance" -Headers $Headers -Method Get
        Write-Host "Créditos Restantes: $($res.subscription.generations) gerações disponíveis (Plano: $($res.subscription.status))" -ForegroundColor Green
        return $res
    } catch {
        Write-Error "Erro ao consultar saldo: $_"
    }
}

function New-Character4D {
    param(
        [string]$CharacterPrompt,
        [string]$CharName,
        [int]$Dimensions = 48,
        [string]$TargetDir = "assets/characters"
    )

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    }

    Write-Host "[PixelLab] Criando personagem 4-direções: $CharName" -ForegroundColor Cyan
    Write-Host "Prompt: $CharacterPrompt" -ForegroundColor Gray

    $body = @{
        description = $CharacterPrompt
        image_size = @{
            width  = $Dimensions
            height = $Dimensions
        }
        outline = "single color black outline"
        shading = "basic shading"
        detail = "medium detail"
    } | ConvertTo-Json

    try {
        $createRes = Invoke-RestMethod -Uri "$BaseUrl/create-character-with-4-directions" -Headers $Headers -Method Post -Body $body
        $jobId = $createRes.background_job_id
        $charId = $createRes.character_id

        Write-Host "Trabalho iniciado (Job ID: $jobId | Character ID: $charId)" -ForegroundColor Yellow
        Write-Host "Aguardando geração do PixelLab..." -ForegroundColor Yellow

        $maxAttempts = 30
        $attempt = 0
        $completed = $false

        while ($attempt -lt $maxAttempts -and -not $completed) {
            Start-Sleep -Seconds 5
            $attempt++
            $jobStatus = Invoke-RestMethod -Uri "$BaseUrl/background-jobs/$jobId" -Headers $Headers -Method Get

            Write-Host "Tentativa $($attempt): Status = $($jobStatus.status)" -ForegroundColor Gray

            if ($jobStatus.status -eq "completed" -or $jobStatus.status -eq "succeeded") {
                $completed = $true
            } elseif ($jobStatus.status -eq "failed") {
                Write-Error "A geração falhou no PixelLab: $($jobStatus.error)"
                return
            }
        }

        if (-not $completed) {
            Write-Warning "Tempo limite excedido aguardando o job. Verifique mais tarde com o Character ID: $charId"
            return
        }

        # Baixar detalhes do personagem
        $charDetail = Invoke-RestMethod -Uri "$BaseUrl/characters/$charId" -Headers $Headers -Method Get

        Write-Host "[PixelLab] Geração concluída com sucesso! Baixando rotações..." -ForegroundColor Green

        $charFolder = Join-Path $TargetDir $CharName
        if (-not (Test-Path $charFolder)) {
            New-Item -ItemType Directory -Force -Path $charFolder | Out-Null
        }

        # Salvar metadata
        $metaPath = Join-Path $charFolder "metadata.json"
        $charDetail | ConvertTo-Json -Depth 5 | Set-Content -Path $metaPath

        # Baixar imagens das direções
        if ($charDetail.rotation_urls) {
            foreach ($dir in $charDetail.rotation_urls.psobject.properties) {
                $dirName = $dir.Name
                $imgUrl = $dir.Value
                if ($imgUrl) {
                    $outPath = Join-Path $charFolder "$dirName.png"
                    Invoke-WebRequest -Uri $imgUrl -OutFile $outPath
                    Write-Host "  -> Salvo: $dirName.png" -ForegroundColor Green
                }
            }
        }

        # Baixar Spritesheet se disponível
        try {
            $sheetUrl = "$BaseUrl/characters/$charId/spritesheet"
            $sheetOut = Join-Path $charFolder "spritesheet.png"
            Invoke-WebRequest -Uri $sheetUrl -Headers $Headers -OutFile $sheetOut
            Write-Host "  -> Salvo: spritesheet.png" -ForegroundColor Green
        } catch {
            Write-Host "Spritesheet individual não retornado diretamente, direções salvas com sucesso." -ForegroundColor Gray
        }

        Write-Host "[PixelLab] Personagem '$CharName' pronto na pasta: $charFolder" -ForegroundColor Cyan
        return $charDetail
    } catch {
        Write-Error "Erro na chamada da API: $_"
    }
}

function Get-CharDetails {
    param([string]$TargetId)
    $res = Invoke-RestMethod -Uri "$BaseUrl/characters/$TargetId" -Headers $Headers -Method Get
    Write-Host "Personagem: $($res.name) | Template: $($res.template_id)" -ForegroundColor Green
    Write-Host "Animações disponíveis:" -ForegroundColor Cyan
    $res.available_animations | ForEach-Object { Write-Host " - $_" -ForegroundColor Gray }
    return $res
}

function New-Animation {
    param(
        [string]$TargetId,
        [string]$AnimId = "walking",
        [string]$AnimMode = "template",
        [string]$TargetDir = "assets/daniel_ragnar/anim_walk_improved"
    )

    Write-Host "[PixelLab] Criando animação '$AnimId' (Mode: $AnimMode, AI Freedom: 0) para $TargetId..." -ForegroundColor Cyan
    
    $body = @{
        character_id = $TargetId
        template_animation_id = $AnimId
        mode = $AnimMode
        ai_freedom = 0
    } | ConvertTo-Json

    try {
        $res = Invoke-RestMethod -Uri "$BaseUrl/animate-character" -Headers $Headers -Method Post -Body $body
        $jobId = $res.background_job_id
        Write-Host "Job iniciado: $jobId" -ForegroundColor Yellow

        $maxAttempts = 40
        $attempt = 0
        $completed = $false
        while ($attempt -lt $maxAttempts -and -not $completed) {
            Start-Sleep -Seconds 5
            $attempt++
            $status = Invoke-RestMethod -Uri "$BaseUrl/background-jobs/$jobId" -Headers $Headers -Method Get
            Write-Host "Tentativa $($attempt): $($status.status)" -ForegroundColor Gray
            if ($status.status -eq "completed" -or $status.status -eq "succeeded") {
                $completed = $true
            } elseif ($status.status -eq "failed") {
                Write-Error "Falhou: $($status.error)"
                return
            }
        }

        if (-not $completed) {
            Write-Warning "Tempo limite excedido."
            return
        }

        Write-Host "Animação concluída! Obtendo detalhes..." -ForegroundColor Green
        $charDetail = Invoke-RestMethod -Uri "$BaseUrl/characters/$TargetId" -Headers $Headers -Method Get
        
        if (-not (Test-Path $TargetDir)) {
            New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
        }

        # Salvar metadata completo
        $charDetail | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $TargetDir "animation_metadata.json")
        Write-Host "Salvo em $TargetDir" -ForegroundColor Green
        return $charDetail
    } catch {
        Write-Error "Erro: $_"
    }
}

# Execução baseada na ação
switch ($Action.ToLower()) {
    "balance" {
        Get-Balance
    }
    "details" {
        if (-not $CharId) { $CharId = "e3cc8aa7-f696-453f-b3d9-3809e52692d3" }
        Get-CharDetails -TargetId $CharId
    }
    "animate" {
        if (-not $CharId) { $CharId = "e3cc8aa7-f696-453f-b3d9-3809e52692d3" }
        New-Animation -TargetId $CharId -AnimId $TemplateAnimation -AnimMode $Mode -TargetDir $OutputDir
    }
    "character" {
        if (-not $Prompt) {
            Write-Error "Informe o parâmetro -Prompt para criar o personagem."
            return
        }
        New-Character4D -CharacterPrompt $Prompt -CharName $Name -Dimensions $Size -TargetDir $OutputDir
    }
    default {
        Write-Host "Ação desconhecida: $Action. Use 'balance', 'details', 'animate' ou 'character'." -ForegroundColor Yellow
    }
}
