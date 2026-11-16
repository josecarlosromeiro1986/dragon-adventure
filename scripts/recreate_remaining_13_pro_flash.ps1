$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$allGroups = @(
    # Grupo 1: NPCs + Esqueleto
    @(
        @{
            id          = "aldeao"
            name        = "Aldeao da Vila"
            template_id = "mannequin"
            size        = 64
            prompt      = "wise medieval village elder man, long white-gray beard, warm brown rustic wool tunic, wooden walking staff, kind eyes, classic 16-bit top-down JRPG pixel art NPC"
        },
        @{
            id          = "vendedor"
            name        = "Vendedor"
            template_id = "mannequin"
            size        = 64
            prompt      = "cheerful medieval RPG merchant shopkeeper, wearing royal blue vest over white shirt, leather apron, gold coin pouch on belt and merchant cap, classic 16-bit top-down JRPG pixel art NPC"
        },
        @{
            id          = "explorador"
            name        = "Explorador"
            template_id = "mannequin"
            size        = 64
            prompt      = "seasoned adventure scout explorer, wearing forest green hooded ranger cloak, leather adventurer hat, compass and large travel backpack with rolled map, classic 16-bit top-down JRPG pixel art NPC"
        },
        @{
            id          = "barao"
            name        = "Barao Ragnar"
            template_id = "mannequin"
            size        = 64
            prompt      = "noble warrior father Baron Ragnar, heroic middle-aged knight with brown hair and beard, wearing ornate battle-worn silver plate armor, crimson red royal cape and golden shoulder pauldrons, classic 16-bit top-down JRPG pixel art hero"
        },
        @{
            id          = "esqueleto"
            name        = "Esqueleto"
            template_id = "mannequin"
            size        = 64
            prompt      = "undead dungeon skeleton warrior monster, white skull and ribcage bones, tattered dark iron armor scraps, glowing cyan undead eyes, holding a notched bone sword and small round shield, classic 16-bit top-down RPG pixel art enemy"
        }
    ),
    # Grupo 2: Monstros da Caverna/Castelo + Lobisomem
    @(
        @{
            id          = "humano_minerador"
            name        = "Humano Minerador"
            template_id = "mannequin"
            size        = 64
            prompt      = "corrupted underground cave miner enemy, wearing yellow brass mining helmet with glowing lantern, soot-stained overalls, glowing red possessed eyes, holding a heavy iron pickaxe, classic 16-bit top-down RPG pixel art enemy"
        },
        @{
            id          = "robo"
            name        = "Robo"
            template_id = "mannequin"
            size        = 64
            prompt      = "steampunk iron patrol robot automaton monster, bulky riveted steel and brass mechanical body, glowing red cyclops visor eye, steam pipes and clamp claws, classic 16-bit top-down RPG pixel art enemy"
        },
        @{
            id          = "fantasma"
            name        = "Fantasma"
            template_id = "custom"
            size        = 64
            prompt      = "spooky floating spectral ghost phantom monster, translucent glowing cyan and pale blue ectoplasm shroud, tattered wispy tail instead of legs, glowing hollow eyes and eerie aura, classic 16-bit top-down RPG pixel art enemy"
        },
        @{
            id          = "lobisomem"
            name        = "Lobisomem"
            template_id = "mannequin"
            size        = 64
            prompt      = "ferocious giant werewolf beast boss, muscular hunched dark gray wolf-man monster, snarling snout with sharp white fangs, glowing yellow eyes, torn pants and huge razor-sharp claws, classic 16-bit top-down RPG pixel art boss"
        }
    ),
    # Grupo 3: Grandes Chefes (Robô Toupeira Serra, Robô Aranha, Dragão, Lunário)
    @(
        @{
            id          = "robo_toupeira_serra"
            name        = "Robo Toupeira de Serra"
            template_id = "bear"
            size        = 64
            prompt      = "giant mechanical steampunk robot mole boss standing on all four legs, heavy riveted steel and brass armor plating, glowing red optical sensors, iron drill snout, giant steel digging claws and a massive spinning circular saw blade mounted on its back, classic 16-bit top-down RPG pixel art boss"
        },
        @{
            id          = "robo_aranha"
            name        = "Robo Aranha"
            template_id = "custom"
            size        = 64
            prompt      = "giant mechanical steampunk spider boss, eight articulated iron and brass spider legs, dark steel arachnid carapace abdomen with glowing red energy core and multiple glowing red spider eyes, classic 16-bit top-down RPG pixel art boss"
        },
        @{
            id          = "dragao"
            name        = "Dragao"
            template_id = "custom"
            size        = 64
            prompt      = "fierce crimson red fire dragon boss, reptilian draconic beast body with golden horns, sharp fangs, glowing fiery orange eyes, scales, clawed feet and large spread bat-like dragon wings, classic 16-bit top-down RPG pixel art boss"
        },
        @{
            id          = "lunario"
            name        = "Deus Dragao Lunario"
            template_id = "custom"
            size        = 64
            prompt      = "supreme Dragon God Lunario final boss, majestic cosmic dark purple and obsidian dragon deity with golden horns, glowing violet energy core on chest, starry cosmic aura and massive spread purple-gold dragon wings, classic 16-bit top-down RPG pixel art final boss"
        }
    )
)

$groupNum = 0
foreach ($group in $allGroups) {
    $groupNum++
    Write-Host "`n=======================================================" -ForegroundColor Magenta
    Write-Host "Iniciando Sub-Lote $groupNum ($($group.Count) personagens em paralelo)..." -ForegroundColor Magenta
    Write-Host "=======================================================" -ForegroundColor Magenta

    $activeJobs = @()
    foreach ($c in $group) {
        Write-Host "[PixelLab Pro Flash] Enfileirando: $($c.id) (template=$($c.template_id))" -ForegroundColor Cyan
        $body = @{
            name        = $c.name
            description = $c.prompt
            view        = "low top-down"
            template_id = $c.template_id
            image_size  = @{
                width  = $c.size
                height = $c.size
            }
        } | ConvertTo-Json

        try {
            $res = Invoke-RestMethod -Uri "$BaseUrl/create-character-pro-flash" -Headers $Headers -Method Post -Body $body
            Write-Host "  -> Iniciado! CharID: $($res.character_id) | JobID: $($res.background_job_id)" -ForegroundColor Yellow
            $activeJobs += @{
                id      = $c.id
                char_id = $res.character_id
                job_id  = $res.background_job_id
                done    = $false
            }
            Start-Sleep -Seconds 2
        } catch {
            Write-Warning "Erro ao iniciar $($c.id): $_"
            if ($_.ErrorDetails) {
                Write-Warning $_.ErrorDetails.Message
            }
        }
    }

    $attempt = 0
    while (($activeJobs | Where-Object { -not $_.done }).Count -gt 0 -and $attempt -lt 90) {
        Start-Sleep -Seconds 6
        $attempt++
        foreach ($j in $activeJobs) {
            if ($j.done) { continue }
            try {
                $charDetail = Invoke-RestMethod -Uri "$BaseUrl/characters/$($j.char_id)" -Headers $Headers -Method Get
                Write-Host "  [Sub-Lote $groupNum | #$attempt] $($j.id): status=$($charDetail.status)" -ForegroundColor Gray
                if ($charDetail.status -eq "completed") {
                    $j.done = $true
                    $charFolder = Join-Path "assets" $j.id
                    if (-not (Test-Path $charFolder)) {
                        New-Item -ItemType Directory -Force -Path $charFolder | Out-Null
                    }
                    Get-ChildItem -Path $charFolder -Filter "*.import" -File | Remove-Item -Force -ErrorAction SilentlyContinue
                    $charDetail | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $charFolder "metadata.json")

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
                    Write-Host "  [OK] $($j.id) recriado em Pro Flash e salvo em $charFolder!" -ForegroundColor Green
                } elseif ($charDetail.status -eq "failed") {
                    $j.done = $true
                    Write-Warning "  [FALHA] $($j.id) falhou!"
                }
            } catch {
                Write-Warning "  Erro ao consultar $($j.id): $_"
            }
        }
    }
}

Write-Host "`nTodos os 13 personagens, monstros e chefes foram recriados em Pro Flash V3!" -ForegroundColor Green
powershell -ExecutionPolicy Bypass -File scripts\pixellab.ps1 -Action balance
