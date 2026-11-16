$ApiKey = $env:ELEVENLABS_API_KEY; if ([string]::IsNullOrWhiteSpace($ApiKey)) { throw "Defina a variavel de ambiente ELEVENLABS_API_KEY antes de executar este script." }
$BaseUrl = "https://api.elevenlabs.io/v1"
$Headers = @{
    "xi-api-key"   = $ApiKey
    "Content-Type" = "application/json; charset=utf-8"
}

$sfxDir = "assets/audio/sfx"
$voicesDir = "assets/audio/voices"
if (-not (Test-Path $sfxDir)) { New-Item -ItemType Directory -Force -Path $sfxDir | Out-Null }
if (-not (Test-Path $voicesDir)) { New-Item -ItemType Directory -Force -Path $voicesDir | Out-Null }

$sfxList = @(
    @{ name = "sword_slash"; dur = 0.8; prompt = "retro 16-bit RPG sharp sword slash whoosh sound effect" },
    @{ name = "hammer_smash"; dur = 1.0; prompt = "heavy warhammer blunt crushing ground impact smash sound effect" },
    @{ name = "magic_fireball"; dur = 1.0; prompt = "magic fireball launch whoosh and burning fire burst sound effect" },
    @{ name = "magic_tornado"; dur = 1.2; prompt = "swirling wind vortex tornado gust air whoosh sound effect" },
    @{ name = "magic_water_bomb"; dur = 1.0; prompt = "magical water bomb splash explosion bursting liquid sound effect" },
    @{ name = "cash_pickup"; dur = 0.7; prompt = "crisp paper money bill pickup flutter and bright RPG chime" },
    @{ name = "eat_food"; dur = 0.8; prompt = "quick video game eating apple crunch and warm health recovery chime" },
    @{ name = "boss_roar"; dur = 1.8; prompt = "terrifying deep monster boss roar echoing in dungeon arena" }
)

foreach ($s in $sfxList) {
    $outPath = Join-Path $sfxDir "$($s.name).mp3"
    if (Test-Path $outPath) {
        Write-Host "[Skip SFX] $outPath já existe." -ForegroundColor Gray
        continue
    }
    Write-Host "[ElevenLabs SFX] Gerando $($s.name).mp3 ($($s.dur)s)..." -ForegroundColor Cyan
    $body = @{
        text             = $s.prompt
        duration_seconds = $s.dur
    } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri "$BaseUrl/sound-generation" -Headers $Headers -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -OutFile $outPath
        Write-Host "  -> [OK] Salvo em $outPath" -ForegroundColor Green
    } catch {
        Write-Warning "  -> Erro ao gerar SFX $($s.name): $_"
    }
}

$ttsList = @(
    @{ name = "aldeao_intro"; voice = "JBFqnCBsd6RMkjVDRZzb"; text = "Daniel! Apenas a nossa Vila Barão Ragnar resistiu ao Deus Dragão Lunário. Fique forte nas caçadas e traga seu pai de volta!" },
    @{ name = "vendedor_ola"; voice = "CwhRBWXzGAHq8TQ4Fs17"; text = "Bem-vindo, pequeno guerreiro! O que suas notas de dinheiro podem comprar hoje?" },
    @{ name = "explorador_dica"; voice = "TX3LPaxmHKxFdv7VOQHJ"; text = "Cuidado, Daniel! Use as magias elementais certas contra cada monstro e desafie o chefe quando estiver pronto!" },
    @{ name = "lunario_desafio"; voice = "N2lVS1w4EtoT3dr4eOWO"; text = "Tolo mortal... A luz deste mundo se apagará sob as asas de Lunário!" },
    @{ name = "barao_resgate"; voice = "SOYHLrjzK2X1ezoPC6cr"; text = "Daniel, meu filho! Você derrotou Lunário e veio me salvar com sua faixa vermelha! Você é o verdadeiro Último Herói!" }
)

foreach ($t in $ttsList) {
    $outPath = Join-Path $voicesDir "$($t.name).mp3"
    if (Test-Path $outPath) {
        Write-Host "[Skip TTS] $outPath já existe." -ForegroundColor Gray
        continue
    }
    Write-Host "[ElevenLabs TTS] Gerando $($t.name).mp3..." -ForegroundColor Cyan
    $body = @{
        text     = $t.text
        model_id = "eleven_multilingual_v2"
        voice_settings = @{
            stability        = 0.55
            similarity_boost = 0.78
        }
    } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri "$BaseUrl/text-to-speech/$($t.voice)" -Headers $Headers -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -OutFile $outPath
        Write-Host "  -> [OK] Salvo em $outPath" -ForegroundColor Green
    } catch {
        Write-Warning "  -> Erro ao gerar TTS $($t.name): $_"
    }
}

Write-Host "`nLote 3 de Áudio (SFX + Dublagens TTS) finalizado!" -ForegroundColor Green
powershell -ExecutionPolicy Bypass -File scripts\elevenlabs.ps1 -Action balance
