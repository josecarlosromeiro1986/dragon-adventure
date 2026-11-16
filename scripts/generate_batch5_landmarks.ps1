$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$landmarks = @(
    # Vila Barão Ragnar
    @{ path = "assets/objects/vila_house.png"; w = 96; h = 96; nobg = $true; view = "low top-down"; prompt = "cozy medieval village wooden and stone cottage house with red terracotta roof and warm lit windows, classic 16-bit top-down RPG pixel art building" },
    @{ path = "assets/objects/vila_fountain.png"; w = 80; h = 80; nobg = $true; view = "low top-down"; prompt = "single isolated medieval stone circular water fountain with sparkling blue water basin, no surroundings, classic 16-bit top-down RPG pixel art prop" },
    @{ path = "assets/objects/vila_stall.png"; w = 80; h = 80; nobg = $true; view = "low top-down"; prompt = "medieval merchant wooden market stall tent with striped blue and gold awning and crates of apples and potions, classic 16-bit top-down RPG pixel art" },
    @{ path = "assets/objects/barao_statue.png"; w = 64; h = 80; nobg = $true; view = "low top-down"; prompt = "heroic stone and gold pedestal statue of a noble knight warrior with sword and cape, classic 16-bit top-down RPG pixel art monument" },

    # Floresta
    @{ path = "assets/objects/floresta_campfire.png"; w = 48; h = 48; nobg = $true; view = "low top-down"; prompt = "warm glowing camp fire over crossed logs and small stones with bright orange flames, classic 16-bit top-down RPG pixel art prop" },
    @{ path = "assets/objects/floresta_bush.png"; w = 48; h = 48; nobg = $true; view = "low top-down"; prompt = "dense lush dark green forest berry bush shrub, classic 16-bit top-down RPG pixel art foliage" },
    @{ path = "assets/objects/floresta_log.png"; w = 64; h = 48; nobg = $true; view = "low top-down"; prompt = "single isolated fallen mossy hollow oak tree log, no background trees, classic 16-bit top-down RPG pixel art obstacle" },

    # Caverna
    @{ path = "assets/objects/caverna_cart.png"; w = 64; h = 64; nobg = $true; view = "low top-down"; prompt = "wooden and iron underground mining cart filled with glowing cyan ore gems on short iron rail track, classic 16-bit top-down RPG pixel art" },
    @{ path = "assets/objects/caverna_crystal.png"; w = 48; h = 64; nobg = $true; view = "low top-down"; prompt = "tall glowing cyan magic mine crystal formation sprouting from dark slate rock, classic 16-bit top-down RPG pixel art" },
    @{ path = "assets/objects/caverna_gears.png"; w = 64; h = 64; nobg = $true; view = "low top-down"; prompt = "steampunk brass and dark iron industrial boiler pipe machine with large bronze gears, classic 16-bit top-down RPG pixel art prop" },

    # Castelo de Lunário
    @{ path = "assets/objects/castelo_torch.png"; w = 48; h = 64; nobg = $true; view = "low top-down"; prompt = "dark obsidian gothic iron brazier pedestal burning with bright mystical purple violet flames, classic 16-bit top-down RPG pixel art" },
    @{ path = "assets/objects/castelo_statue.png"; w = 64; h = 80; nobg = $true; view = "low top-down"; prompt = "menacing dark obsidian stone gargoyle dragon statue on cracked pedestal with glowing violet eyes, classic 16-bit top-down RPG pixel art" },
    @{ path = "assets/objects/castelo_throne.png"; w = 80; h = 80; nobg = $true; view = "low top-down"; prompt = "grand dark obsidian dragon king throne altar adorned with gold spikes and glowing purple rune circle, classic 16-bit top-down RPG pixel art" },

    # Cabana Inimiga
    @{ path = "assets/objects/cabana_fence.png"; w = 64; h = 48; nobg = $true; view = "low top-down"; prompt = "rusted dark iron fortress prison bars fence barricade with stone posts, classic 16-bit top-down RPG pixel art" }
)

foreach ($a in $landmarks) {
    $dir = Split-Path -Parent $a.path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    if (Test-Path $a.path) {
        Write-Host "[Skip] $($a.path) já existe." -ForegroundColor Gray
        continue
    }

    Write-Host "[PixelLab Pixen] Gerando $($a.path) ($($a.w)x$($a.h))..." -ForegroundColor Cyan
    $body = @{
        description   = $a.prompt
        image_size    = @{ width = $a.w; height = $a.h }
        no_background = $a.nobg
        view          = $a.view
        detail        = "highly detailed"
        outline       = "single color black outline"
    } | ConvertTo-Json

    try {
        $res = Invoke-RestMethod -Uri "$BaseUrl/create-image-pixen" -Headers $Headers -Method Post -Body $body
        $b64 = $res.image.base64
        if ($b64 -match "^data:image/\w+;base64,(.+)$") {
            $b64 = $Matches[1]
        }
        $bytes = [Convert]::FromBase64String($b64)
        [IO.File]::WriteAllBytes((Join-Path (Get-Location) $a.path), $bytes)
        Write-Host "  -> [OK] Salvo em $($a.path)" -ForegroundColor Green
    } catch {
        Write-Warning "  -> Erro ao gerar $($a.path): $_"
        if ($_.ErrorDetails) {
            Write-Warning $_.ErrorDetails.Message
        }
    }
}

Write-Host "`nBatch 5 Landmarks finalizado!" -ForegroundColor Green
powershell -ExecutionPolicy Bypass -File scripts\pixellab.ps1 -Action balance
