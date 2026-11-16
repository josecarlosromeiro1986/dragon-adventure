$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$BaseUrl = "https://api.pixellab.ai/v2"
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$uiAssets = @(
    # Painéis 9-slice (128x128)
    @{ path = "assets/ui/panel_stone.png"; w = 128; h = 128; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing 2D UI square window frame made of carved dark slate stone with thin oak inner border and tiny brass corner rivets, uniform solid dark charcoal gray flat interior in the center for 9-slice UI scaling, crisp 16-bit pixel art RPG interface, no text, no icons" },
    @{ path = "assets/ui/panel_parchment.png"; w = 128; h = 128; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing 2D UI square panel made of warm aged medieval parchment framed by a thin dark oak wood border and tiny gold corner pins, uniform flat cream beige interior in the center for readable RPG text and 9-slice scaling, crisp 16-bit pixel art UI, no text" },
    @{ path = "assets/ui/panel_gold.png"; w = 128; h = 128; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing 2D UI square RPG frame with ornate burnished gold and dark crimson border trim and uniform solid dark slate interior in the center for 9-slice victory and boss windows, crisp 16-bit pixel art UI, no text" },
    @{ path = "assets/ui/panel_slot.png"; w = 48; h = 48; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing 2D square carved dark stone medieval RPG inventory slot frame with thin brass gold beveled border and empty dark slate center, crisp 16-bit pixel art UI, no text, no item" },

    # Botões 9-slice (96x32)
    @{ path = "assets/ui/btn_stone.png"; w = 96; h = 32; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing wide horizontal rectangular medieval RPG button made of dark carved slate stone with thin bronze trim border, clean empty dark slate interior for text, crisp 16-bit pixel art UI, no text" },
    @{ path = "assets/ui/btn_green.png"; w = 96; h = 32; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing wide horizontal rectangular medieval RPG button made of glowing emerald green crystal stone with gold brass border and corner studs, clean empty emerald interior for text, crisp 16-bit pixel art UI, no text" },
    @{ path = "assets/ui/btn_gold.png"; w = 96; h = 32; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing wide horizontal rectangular medieval RPG button made of warm burnished bronze and gold metal with riveted border, clean empty warm brown-gold interior for text, crisp 16-bit pixel art UI, no text" },
    @{ path = "assets/ui/btn_crimson.png"; w = 96; h = 32; nobg = $true; outline = "single color black outline"; prompt = "flat front-facing wide horizontal rectangular medieval RPG button made of deep crimson red enamel with ornate gold border and corner studs, clean empty dark crimson interior for text, crisp 16-bit pixel art UI, no text" },

    # Ícones HUD e Modais (32x32)
    @{ path = "assets/ui/icon_hp_orb.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "glowing ruby red glass health orb amulet set in ornate golden brass frame, centered 16-bit fantasy RPG pixel art UI icon, no text" },
    @{ path = "assets/ui/icon_mana_orb.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "glowing sapphire blue glass mana crystal orb set in ornate silver and gold frame, centered 16-bit fantasy RPG pixel art UI icon, no text" },
    @{ path = "assets/ui/icon_level_crest.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "small winged golden medieval knight shield crest emblem, centered 16-bit fantasy RPG pixel art UI icon, no text" },
    @{ path = "assets/ui/icon_map_scroll.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "rolled antique parchment treasure map scroll tied with red wax seal, centered 16-bit fantasy RPG pixel art UI icon, no text" },
    @{ path = "assets/ui/icon_bestiary_book.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "brown leather-bound medieval bestiary tome book with gold brass clasps, centered 16-bit fantasy RPG pixel art UI icon, no text" },
    @{ path = "assets/ui/icon_boss_crest.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "fierce golden dragon head emblem crest on crimson shield, centered 16-bit fantasy RPG pixel art UI icon, no text" },
    @{ path = "assets/ui/icon_padlock.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "heavy medieval iron padlock with keyhole, centered 16-bit fantasy RPG pixel art UI icon, no text" },
    @{ path = "assets/ui/icon_sound.png"; w = 32; h = 32; nobg = $true; outline = "single color black outline"; prompt = "golden medieval brass herald trumpet horn icon, centered 16-bit fantasy RPG pixel art UI icon, no text" }
)

foreach ($a in $uiAssets) {
    $dir = Split-Path -Parent $a.path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    if (Test-Path $a.path) {
        Write-Host "[Skip] $($a.path) já existe." -ForegroundColor Gray
        continue
    }

    Write-Host "[PixelLab Pixen UI] Gerando $($a.path) ($($a.w)x$($a.h))..." -ForegroundColor Cyan
    $body = @{
        description   = $a.prompt
        image_size    = @{ width = $a.w; height = $a.h }
        no_background = $a.nobg
        detail        = "medium detail"
        outline       = $a.outline
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

Write-Host "`nGeracao de UI Medieval finalizada!" -ForegroundColor Green
powershell -ExecutionPolicy Bypass -File scripts\pixellab.ps1 -Action balance