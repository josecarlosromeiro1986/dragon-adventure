$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$assets = @(
    # 1. Texturas de Solo (Tiles 64x64 sem transparência)
    @{ path = "assets/tiles/ground_vila.png"; w = 64; h = 64; nobg = $false; view = "high top-down"; prompt = "flat top-down 16-bit RPG village grassy ground texture with warm cobblestone pebbles, seamless tileable floor pattern, dark muted palette" },
    @{ path = "assets/tiles/ground_floresta.png"; w = 64; h = 64; nobg = $false; view = "high top-down"; prompt = "flat top-down 16-bit RPG dark enchanted forest grass, moss and dirt floor texture, seamless tileable ground pattern" },
    @{ path = "assets/tiles/ground_caverna.png"; w = 64; h = 64; nobg = $false; view = "high top-down"; prompt = "flat top-down 16-bit RPG dark underground cave slate stone floor texture with small cracks, seamless tileable ground pattern" },
    @{ path = "assets/tiles/ground_castelo.png"; w = 64; h = 64; nobg = $false; view = "high top-down"; prompt = "flat top-down 16-bit RPG dark obsidian dragon fortress stone floor tiles with subtle purple and ember cracks, seamless tileable ground" },
    @{ path = "assets/tiles/ground_cabana.png"; w = 64; h = 64; nobg = $false; view = "high top-down"; prompt = "flat top-down 16-bit RPG sunlit forest clearing green grass and tiny wildflowers ground texture, seamless tileable floor" },

    # 2. Obstáculos e Cenário dos Biomas (com fundo transparente)
    @{ path = "assets/objects/obs_vila.png"; w = 64; h = 64; nobg = $true; view = "low top-down"; prompt = "medieval village wooden barrels and supply crate prop, classic 16-bit top-down RPG pixel art object" },
    @{ path = "assets/objects/obs_floresta.png"; w = 64; h = 64; nobg = $true; view = "low top-down"; prompt = "lush ancient fantasy forest oak tree with thick brown trunk and green canopy, classic 16-bit top-down RPG pixel art tree" },
    @{ path = "assets/objects/obs_caverna.png"; w = 64; h = 64; nobg = $true; view = "low top-down"; prompt = "underground mine jagged dark rock boulder with glowing cyan crystal cluster, classic 16-bit top-down RPG pixel art obstacle" },
    @{ path = "assets/objects/obs_castelo.png"; w = 64; h = 64; nobg = $true; view = "low top-down"; prompt = "dark obsidian gothic dragon fortress stone pillar with glowing violet and fiery runes, classic 16-bit top-down RPG pixel art column" },
    @{ path = "assets/objects/obs_cabana.png"; w = 64; h = 64; nobg = $true; view = "low top-down"; prompt = "tall green pine tree with rustic wooden fence post, classic 16-bit top-down RPG pixel art object" },
    @{ path = "assets/objects/cabana_house.png"; w = 96; h = 96; nobg = $true; view = "low top-down"; prompt = "rustic medieval wooden cabin hut in the forest with timber roof, stone chimney and iron-barred window, classic 16-bit top-down RPG pixel art building" },

    # 3. Cédula de Dinheiro e Projéteis de Magia (32x32 com fundo transparente)
    @{ path = "assets/items/cash_note.png"; w = 32; h = 32; nobg = $true; view = "high top-down"; prompt = "crisp green paper money banknote bill currency note with gold emblem border, 16-bit RPG pixel art item icon" },
    @{ path = "assets/spells/fireball.png"; w = 32; h = 32; nobg = $true; view = "high top-down"; prompt = "blazing orange and yellow magical fireball orb projectile with flame sparks, 16-bit RPG pixel art spell icon" },
    @{ path = "assets/spells/tornado.png"; w = 32; h = 32; nobg = $true; view = "low top-down"; prompt = "swirling cyan and white magical wind tornado vortex cyclone projectile, 16-bit RPG pixel art spell icon" },
    @{ path = "assets/spells/water_bomb.png"; w = 32; h = 32; nobg = $true; view = "high top-down"; prompt = "glowing deep blue and aqua magical water bomb sphere orb projectile with water droplets, 16-bit RPG pixel art spell icon" },

    # 4. Ícones da Loja e Comidas (32x32 com fundo transparente)
    @{ path = "assets/items/maca.png"; w = 32; h = 32; nobg = $true; view = "side"; prompt = "shiny red apple fruit with green leaf, 16-bit RPG pixel art item icon" },
    @{ path = "assets/items/pao.png"; w = 32; h = 32; nobg = $true; view = "side"; prompt = "golden baked medieval artisan bread loaf, 16-bit RPG pixel art item icon" },
    @{ path = "assets/items/carne_assada.png"; w = 32; h = 32; nobg = $true; view = "side"; prompt = "juicy roasted meat leg on bone, 16-bit RPG pixel art item icon" },
    @{ path = "assets/items/banquete_real.png"; w = 32; h = 32; nobg = $true; view = "side"; prompt = "royal golden feast platter with roast turkey and fruits, 16-bit RPG pixel art item icon" },
    @{ path = "assets/items/weapon_sword.png"; w = 32; h = 32; nobg = $true; view = "side"; prompt = "heroic silver knight broadsword with golden hilt, 16-bit RPG pixel art weapon icon" },
    @{ path = "assets/items/weapon_hammer.png"; w = 32; h = 32; nobg = $true; view = "side"; prompt = "heavy iron and gold warhammer battle hammer, 16-bit RPG pixel art weapon icon" },
    @{ path = "assets/items/armor_chest.png"; w = 32; h = 32; nobg = $true; view = "side"; prompt = "shining silver and gold knight breastplate armor, 16-bit RPG pixel art armor icon" }
)

foreach ($a in $assets) {
    $dir = Split-Path -Parent $a.path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    if (Test-Path $a.path) {
        Write-Host "[Skip] $($a.path) já existe." -ForegroundColor Gray
        continue
    }

    Write-Host "[PixelLab Pixen] Gerando $($a.path) ($($a.w)x$($a.h), nobg=$($a.nobg))..." -ForegroundColor Cyan
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

Write-Host "`nLote 2 (Cenários, Obstáculos, Magias e Ícones) finalizado!" -ForegroundColor Green
