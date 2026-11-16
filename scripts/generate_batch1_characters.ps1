$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$characters = @(
    @{ id = "aldeao"; size = 64; prompt = "wise medieval village elder man with gray beard and rustic brown tunic, top-down pixel art RPG NPC" },
    @{ id = "vendedor"; size = 64; prompt = "friendly medieval merchant shopkeeper wearing royal blue vest, apron and gold pouch, top-down pixel art RPG NPC" },
    @{ id = "explorador"; size = 64; prompt = "rugged adventure explorer scout wearing green cloak, hat and big leather backpack, top-down pixel art RPG NPC" },
    @{ id = "barao"; size = 68; prompt = "noble warrior father Baron Ragnar, battle-worn silver knight armor, red cape and heroic brown beard, top-down pixel art RPG hero" },
    @{ id = "esqueleto"; size = 64; prompt = "undead skeleton warrior monster holding a bone sword, glowing eyes, top-down pixel art RPG enemy" },
    @{ id = "humano_minerador"; size = 64; prompt = "corrupted underground miner enemy wearing mining helmet with lantern and holding pickaxe, top-down pixel art RPG" },
    @{ id = "robo"; size = 64; prompt = "steampunk iron patrol robot automaton with glowing red visor and brass gears, top-down pixel art RPG monster" },
    @{ id = "fantasma"; size = 64; prompt = "spooky glowing cyan spectral ghost phantom floating with tattered shroud, top-down pixel art RPG monster" },
    @{ id = "lobisomem"; size = 68; prompt = "ferocious dark gray werewolf beast boss with glowing yellow eyes, fangs and sharp claws, top-down pixel art RPG boss" },
    @{ id = "robo_toupeira_serra"; size = 68; prompt = "giant mechanical steampunk robot mole boss with steel armor plates and spinning circular saw blades, top-down pixel art RPG boss" },
    @{ id = "robo_aranha"; size = 68; prompt = "giant mechanical steampunk spider boss with metal legs, iron carapace and glowing red core, top-down pixel art RPG boss" },
    @{ id = "dragao"; size = 68; prompt = "fierce crimson red fire dragon boss with horns, scales and spread wings, top-down pixel art RPG boss" },
    @{ id = "lunario"; size = 68; prompt = "supreme Dragon God Lunario final boss, dark purple and gold cosmic scales, glowing violet energy wings and horns, top-down pixel art RPG boss" }
)

foreach ($c in $characters) {
    $charFolder = Join-Path "assets" $c.id
    $southFile = Join-Path $charFolder "south.png"
    if (Test-Path $southFile) {
        Write-Host "[Skip] $($c.id) já existe em $charFolder" -ForegroundColor Gray
        continue
    }

    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "[PixelLab] Gerando 4 direções para: $($c.id) ($($c.size)x$($c.size))" -ForegroundColor Cyan
    $body = @{
        description = $c.prompt
        image_size = @{
            width  = $c.size
            height = $c.size
        }
        outline = "single color black outline"
        shading = "basic shading"
        detail = "medium detail"
    } | ConvertTo-Json

    try {
        $createRes = Invoke-RestMethod -Uri "$BaseUrl/create-character-with-4-directions" -Headers $Headers -Method Post -Body $body
        $jobId = $createRes.background_job_id
        $charId = $createRes.character_id
        Write-Host "  Job: $jobId | CharID: $charId" -ForegroundColor Yellow

        $attempt = 0
        $completed = $false
        while ($attempt -lt 45 -and -not $completed) {
            Start-Sleep -Seconds 5
            $attempt++
            $jobStatus = Invoke-RestMethod -Uri "$BaseUrl/background-jobs/$jobId" -Headers $Headers -Method Get
            Write-Host "  [$attempt] $($c.id): $($jobStatus.status)" -ForegroundColor Gray
            if ($jobStatus.status -eq "completed" -or $jobStatus.status -eq "succeeded") {
                $completed = $true
            } elseif ($jobStatus.status -eq "failed") {
                Write-Warning "  Falha no job de $($c.id): $($jobStatus.error)"
                break
            }
        }

        if ($completed) {
            $charDetail = Invoke-RestMethod -Uri "$BaseUrl/characters/$charId" -Headers $Headers -Method Get
            if (-not (Test-Path $charFolder)) {
                New-Item -ItemType Directory -Force -Path $charFolder | Out-Null
            }
            $charDetail | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $charFolder "metadata.json")

            if ($charDetail.rotation_urls) {
                foreach ($dir in $charDetail.rotation_urls.psobject.properties) {
                    $dirName = $dir.Name
                    $imgUrl = $dir.Value
                    if ($imgUrl) {
                        $outPath = Join-Path $charFolder "$dirName.png"
                        Invoke-WebRequest -Uri $imgUrl -OutFile $outPath
                    }
                }
            }
            Write-Host "  [OK] $($c.id) salvo com sucesso!" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Erro ao gerar $($c.id): $_"
    }
}

Write-Host "Lote 1 finalizado!" -ForegroundColor Green
