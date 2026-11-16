$ApiKey = $env:ELEVENLABS_API_KEY; if ([string]::IsNullOrWhiteSpace($ApiKey)) { throw "Defina a variavel de ambiente ELEVENLABS_API_KEY antes de executar este script." }
$BaseUrl = "https://api.elevenlabs.io/v1"
$Headers = @{
    "xi-api-key"   = $ApiKey
    "Content-Type" = "application/json; charset=utf-8"
}

$bgmDir = "assets/audio/bgm"
$voicesDir = "assets/audio/voices"
if (-not (Test-Path $bgmDir)) { New-Item -ItemType Directory -Force -Path $bgmDir | Out-Null }
if (-not (Test-Path $voicesDir)) { New-Item -ItemType Directory -Force -Path $voicesDir | Out-Null }

$bgmList = @(
    @{ name = "bgm_vila"; dur_ms = 45000; prompt = "Tense medieval suspense stealth underscore loop starting immediately at bar one, 88 BPM in D minor. Fortified medieval village expecting an imminent monster siege attack at any moment. Restless rhythmic plucked medieval lute and harpsichord ostinato, nervous pizzicato strings, tense bowed viola and cello swells, quiet rapid frame drum heartbeat pulse, eerie distant medieval war horn warning calls, wooden recorder whispers. No slow ambient intro, immediate rhythmic medieval tension from the first second, no vocals, no modern synths, continuous seamless loop without ending fadeout." },
    @{ name = "bgm_floresta"; dur_ms = 48000; prompt = "Medieval fantasy epic adventure battle music, level 1 intensity, set in a dark enchanted medieval forest, 118 BPM. Driven by rhythmic medieval lute, vigorous cello and viola ostinato, noble soaring medieval French horns and trumpets, expressive Celtic fiddle and wooden flute weaving an urgent heroic minor melody, steady marching snare and bodhran drums. Energetic, brave, epic medieval quest atmosphere, purely acoustic and orchestral, no modern electronic elements, consistent full energy throughout." },
    @{ name = "bgm_caverna"; dur_ms = 50000; prompt = "Intense dark epic medieval war battle soundtrack, level 2 high intensity, set in deep subterranean mines and fortress caverns, 138 BPM. Heavy pounding medieval war drums, rhythmic iron blacksmith anvil clangs with rolling military snares, aggressive blaring low brass trombones and war horns, fast urgent minor-key violin ostinato, solemn deep male medieval monastic choir chanting without lyrics, threatening relentless momentum, escalating danger. Purely medieval orchestral and percussive, no modern rock or sci-fi synths, consistent high energy." },
    @{ name = "bgm_castelo"; dur_ms = 55000; prompt = "Apocalyptic maximum intensity epic medieval boss battle orchestral soundtrack, level 3 ultimate climax in a gothic dragon castle, 156 BPM. Blazing rapid full string section ostinato, thunderous double timpani and pounding war drums, crashing cymbals, roaring triumphant brass fanfares, dramatic gothic cathedral pipe organ and harpsichord, soaring powerful dramatic choir chanting wordless epic harmonies. Heroic, terrifying, overwhelming final battle intensity against a dragon god. Purely medieval dark fantasy orchestra, maximum dynamic intensity throughout." },
    @{ name = "bgm_cabana"; dur_ms = 40000; prompt = "Warm triumphant medieval orchestral epilogue music after a hard-won victory, 94 BPM. Expressive medieval harp arpeggios, noble heroic French horns, emotional soaring legato strings, gentle medieval lute and acoustic woodwinds. Heartwarming heroic reunion relief, purely authentic medieval orchestral instruments, no modern synths." }
)

foreach ($b in $bgmList) {
    $outPath = Join-Path $bgmDir "$($b.name).mp3"
    if (Test-Path $outPath) {
        Write-Host "[Skip BGM] $outPath já existe." -ForegroundColor Gray
        continue
    }
    Write-Host "[ElevenLabs Music BGM] Gerando $($b.name).mp3 ($($b.dur_ms / 1000)s)..." -ForegroundColor Cyan
    $body = @{
        prompt             = $b.prompt
        music_length_ms    = $b.dur_ms
        force_instrumental = $true
        model_id           = "music_v1"
        output_format      = "mp3_44100_128"
    } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri "$BaseUrl/music" -Headers $Headers -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -OutFile $outPath
        Write-Host "  -> [OK] Salvo em $outPath" -ForegroundColor Green
    } catch {
        Write-Warning "  -> Erro ao gerar BGM $($b.name): $_"
    }
}

# Voz jovem otimista/corajosa (Will) para Daniel Ragnar (com pitch leve ajustado no AudioManager)
$danielVoiceId = "bIHbv24MWmeRgasZH58o"
$danielLines = @(
    @{ name = "daniel_levelup"; text = "Mais forte! Pelo meu pai e pela Vila Barão Ragnar!" },
    @{ name = "daniel_fireball"; text = "Bola de Fogo!" },
    @{ name = "daniel_tornado"; text = "Tornado cortante!" },
    @{ name = "daniel_water_bomb"; text = "Bomba de Água!" },
    @{ name = "daniel_boss_challenge"; text = "Eu não tenho medo! Venha lutar comigo!" },
    @{ name = "daniel_victory"; text = "Pai! Eu consegui! O Deus Dragão Lunário foi derrotado!" }
)

foreach ($t in $danielLines) {
    $outPath = Join-Path $voicesDir "$($t.name).mp3"
    if (Test-Path $outPath) {
        Write-Host "[Skip TTS] $outPath já existe." -ForegroundColor Gray
        continue
    }
    Write-Host "[ElevenLabs TTS - Daniel] Gerando $($t.name).mp3..." -ForegroundColor Cyan
    $body = @{
        text     = $t.text
        model_id = "eleven_multilingual_v2"
        voice_settings = @{
            stability        = 0.45
            similarity_boost = 0.80
        }
    } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri "$BaseUrl/text-to-speech/$danielVoiceId" -Headers $Headers -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -OutFile $outPath
        Write-Host "  -> [OK] Salvo em $outPath" -ForegroundColor Green
    } catch {
        Write-Warning "  -> Erro ao gerar TTS $($t.name): $_"
    }
}

Write-Host "`nLote 4 (BGM por Bioma + Vozes do Daniel Ragnar) finalizado!" -ForegroundColor Green
powershell -ExecutionPolicy Bypass -File scripts\elevenlabs.ps1 -Action balance
