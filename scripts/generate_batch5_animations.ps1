$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$targets = @(
    # 1. Ataque de Daniel Ragnar (v3 golpe heroico)
    @{ id = "daniel_ragnar"; char_id = "97670833-6531-409d-ae0f-243a820dcdb4"; folder = "anim_attack"; mode = "v3"; action = "swinging weapon forward in a fast heroic slash strike"; name = "attack" },

    # 2. Caminhada dos monstros e chefes (mannequin -> walking | bear -> walk-6-frames)
    @{ id = "toupeira"; char_id = "a6953c03-3e58-47da-b68f-574c8769589f"; folder = "anim_walk"; mode = "template"; tpl = "walk-6-frames"; name = "walking" },
    @{ id = "zumbi"; char_id = "d5c6ba2d-80a1-4ef9-9d6b-1c38e0aafa7d"; folder = "anim_walk"; mode = "template"; tpl = "walking"; name = "walking" },
    @{ id = "toupeira_serra"; char_id = "2b6ec924-3e4f-4c0d-87cc-2ecf083e78d9"; folder = "anim_walk"; mode = "template"; tpl = "walk-6-frames"; name = "walking" },
    @{ id = "esqueleto"; char_id = "ac9040f3-9b3b-40c5-b771-25370b55c8cf"; folder = "anim_walk"; mode = "template"; tpl = "walking"; name = "walking" },
    @{ id = "humano_minerador"; char_id = "debe7df7-cfff-4a1b-8573-774cbc0241d2"; folder = "anim_walk"; mode = "template"; tpl = "walking"; name = "walking" },
    @{ id = "robo"; char_id = "06d3b0d6-823c-4c4e-b675-63ab8aaad33e"; folder = "anim_walk"; mode = "template"; tpl = "walking"; name = "walking" },
    @{ id = "lobisomem"; char_id = "3ecfe6fa-80d2-4389-8717-23b2edd29067"; folder = "anim_walk"; mode = "template"; tpl = "walking"; name = "walking" },
    @{ id = "robo_toupeira_serra"; char_id = "5a72d2db-016e-4ecd-aed2-b839425d2247"; folder = "anim_walk"; mode = "template"; tpl = "walk-6-frames"; name = "walking" },

    # 3. Caminhada/Movimento dos monstros e chefes custom (mode v3)
    @{ id = "fantasma"; char_id = "b61d848d-5e8d-499d-9f9d-43f56995f654"; folder = "anim_walk"; mode = "v3"; action = "floating eerily forward swaying translucent spectral shroud"; name = "walking" },
    @{ id = "robo_aranha"; char_id = "e617e621-1346-4455-8350-dafeed21121e"; folder = "anim_walk"; mode = "v3"; action = "scuttling forward moving eight mechanical spider legs"; name = "walking" },
    @{ id = "dragao"; char_id = "2000ffc1-c626-46c9-a8cf-50fb81ea8292"; folder = "anim_walk"; mode = "v3"; action = "flapping crimson dragon wings and marching forward"; name = "walking" },
    @{ id = "lunario"; char_id = "a136a79a-3d6e-4fff-99ce-289db8fce10d"; folder = "anim_walk"; mode = "v3"; action = "floating majestically flapping cosmic purple and gold dragon wings"; name = "walking" }
)

# Processa em sub-lotes de 2 personagens (8 jobs paralelos = limite exato da conta)
$batchSize = 2
for ($i = 0; $i -lt $targets.Count; $i += $batchSize) {
    $end = [Math]::Min($i + $batchSize - 1, $targets.Count - 1)
    $slice = $targets[$i..$end]

    Write-Host "`n=======================================================" -ForegroundColor Magenta
    Write-Host "Iniciando Sub-Lote Anim ($($i + 1)..$($end + 1) de $($targets.Count))..." -ForegroundColor Magenta
    Write-Host "=======================================================" -ForegroundColor Magenta

    $pending = @()
    foreach ($t in $slice) {
        $targetDir = Join-Path "assets/$($t.id)" $t.folder
        $checkFile = Join-Path $targetDir "south/1.png"
        if (Test-Path $checkFile) {
            Write-Host "[Skip] $($t.id)/$($t.folder) já gerado." -ForegroundColor Gray
            continue
        }

        Write-Host "[PixelLab] Enfileirando $($t.id)/$($t.folder) (mode=$($t.mode))..." -ForegroundColor Cyan
        if ($t.mode -eq "template") {
            $bodyObj = @{
                character_id          = $t.char_id
                template_animation_id = $t.tpl
                mode                  = "template"
                directions            = @("south", "north", "east", "west")
                animation_name        = $t.name
            }
        } else {
            $bodyObj = @{
                character_id       = $t.char_id
                mode               = "v3"
                action_description = $t.action
                frame_count        = 4
                keep_first_frame   = $true
                directions         = @("south", "north", "east", "west")
                animation_name     = $t.name
            }
        }

        try {
            $res = Invoke-RestMethod -Uri "$BaseUrl/animate-character" -Headers $Headers -Method Post -Body ($bodyObj | ConvertTo-Json)
            Write-Host "  -> GroupID: $($res.animation_group_id) | Jobs: $($res.background_job_ids.Count)" -ForegroundColor Yellow
            $pending += @{
                target    = $t
                group_id  = $res.animation_group_id
                job_ids   = $res.background_job_ids
                done      = $false
            }
            Start-Sleep -Milliseconds 1200
        } catch {
            Write-Warning "  -> Erro ao enfileirar $($t.id): $_"
            if ($_.ErrorDetails) {
                Write-Warning $_.ErrorDetails.Message
            }
        }
    }

    if ($pending.Count -eq 0) { continue }

    $attempt = 0
    while (($pending | Where-Object { -not $_.done }).Count -gt 0 -and $attempt -lt 85) {
        Start-Sleep -Seconds 6
        $attempt++
        foreach ($p in $pending) {
            if ($p.done) { continue }
            $allJobsDone = $true
            $anyFailed = $false
            foreach ($jid in $p.job_ids) {
                try {
                    $js = Invoke-RestMethod -Uri "$BaseUrl/background-jobs/$jid" -Headers $Headers -Method Get
                    if ($js.status -eq "failed") {
                        $anyFailed = $true
                    } elseif ($js.status -ne "completed" -and $js.status -ne "succeeded") {
                        $allJobsDone = $false
                    }
                } catch {
                    $allJobsDone = $false
                }
            }

            if ($allJobsDone) {
                $p.done = $true
                $t = $p.target
                if ($anyFailed) {
                    Write-Warning "  [PARCIAL/FALHA] Alguns jobs de $($t.id) falharam."
                }
                try {
                    $charDetail = Invoke-RestMethod -Uri "$BaseUrl/characters/$($t.char_id)" -Headers $Headers -Method Get
                    $charDetail | ConvertTo-Json -Depth 8 | Set-Content -Path "assets/$($t.id)/metadata.json"

                    $anim = $charDetail.animations | Where-Object { $_.animation_group_id -eq $p.group_id }
                    if (-not $anim) {
                        $anim = $charDetail.animations | Select-Object -Last 1
                    }

                    $targetDir = Join-Path "assets/$($t.id)" $t.folder
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
                    }
                    Write-Host "  [OK] $($t.id)/$($t.folder) salvo ($($anim.directions.Count) direções)!" -ForegroundColor Green
                } catch {
                    Write-Warning "  -> Erro ao baixar frames de $($t.id): $_"
                }
            } else {
                Write-Host "  [Lote $($i + 1)..$($end + 1) | #$attempt] Aguardando $($p.target.id)..." -ForegroundColor Gray
            }
        }
    }
}

Write-Host "`nBatch 5 Animações concluído!" -ForegroundColor Green
powershell -ExecutionPolicy Bypass -File scripts\pixellab.ps1 -Action balance
