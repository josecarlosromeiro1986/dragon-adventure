$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$characters = @(
    @{
        id          = "daniel_ragnar"
        name        = "Daniel Ragnar"
        template_id = "mannequin"
        size        = 64
        prompt      = "young boy adventurer hero named Daniel Ragnar, cute determined 12-year-old anime JRPG boy with messy spiky brown hair, wearing a thick bright red cloth headband bandana tied around his forehead with two long flowing red cloth tails streaming behind his head, wearing a white short-sleeve tunic under a rustic brown leather vest, brown belt, brown adventurer pants and sturdy leather boots, classic 16-bit top-down RPG pixel art character"
    },
    @{
        id          = "toupeira"
        name        = "Toupeira"
        template_id = "bear"
        size        = 64
        prompt      = "cute fierce subterranean giant mole monster standing on all four legs, plump brown furry mole body, pink mole nose snout, big sharp white digging claws on front paws, angry dark eyes, classic 16-bit top-down RPG pixel art monster"
    },
    @{
        id          = "zumbi"
        name        = "Zumbi da Floresta"
        template_id = "mannequin"
        size        = 64
        prompt      = "shambling undead forest zombie monster, green rotting skin, glowing red undead eyes, tattered medieval peasant shirt and torn pants covered in dark forest moss, outstretched clawing hands, classic 16-bit top-down RPG pixel art enemy"
    },
    @{
        id          = "toupeira_serra"
        name        = "Toupeira de Serra"
        template_id = "bear"
        size        = 64
        prompt      = "giant ferocious boss mole monster standing on all four legs, dark brown fur with heavy iron armor plates and a massive spinning steel circular saw blade mounted vertically on its back, huge steel digging claws and glowing red eyes, classic 16-bit top-down RPG pixel art boss"
    }
)

$activeJobs = @()

foreach ($c in $characters) {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "[PixelLab Pro Flash] Enfileirando recriação: $($c.id) ($($c.size)x$($c.size), template=$($c.template_id))" -ForegroundColor Cyan

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
        Write-Host "  -> Iniciado! CharID: $($res.character_id) | JobID: $($res.background_job_id) | Est.Gens: $($res.estimated_generations)" -ForegroundColor Yellow
        $activeJobs += @{
            id      = $c.id
            char_id = $res.character_id
            job_id  = $res.background_job_id
            done    = $false
        }
    } catch {
        Write-Warning "Erro ao iniciar $($c.id): $_"
        if ($_.ErrorDetails) {
            Write-Warning $_.ErrorDetails.Message
        }
    }
}

Write-Host "`nAguardando conclusão dos $($activeJobs.Count) personagens em paralelo..." -ForegroundColor Cyan

$attempt = 0
while (($activeJobs | Where-Object { -not $_.done }).Count -gt 0 -and $attempt -lt 80) {
    Start-Sleep -Seconds 6
    $attempt++
    foreach ($j in $activeJobs) {
        if ($j.done) { continue }
        try {
            $charDetail = Invoke-RestMethod -Uri "$BaseUrl/characters/$($j.char_id)" -Headers $Headers -Method Get
            Write-Host "  [$attempt] $($j.id): status=$($charDetail.status)" -ForegroundColor Gray
            if ($charDetail.status -eq "completed") {
                $j.done = $true
                $charFolder = Join-Path "assets" $j.id
                if (-not (Test-Path $charFolder)) {
                    New-Item -ItemType Directory -Force -Path $charFolder | Out-Null
                }
                # Remover .import antigos das direções para forçar atualização limpa
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
                Write-Host "  [OK] $($j.id) recriado e salvo em $charFolder!" -ForegroundColor Green
            } elseif ($charDetail.status -eq "failed") {
                $j.done = $true
                Write-Warning "  [FALHA] $($j.id) falhou!"
            }
        } catch {
            Write-Warning "  Erro ao consultar $($j.id): $_"
        }
    }
}

Write-Host "`nRecriação dos 4 primeiros personagens finalizada!" -ForegroundColor Green
