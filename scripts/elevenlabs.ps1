param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "balance",
    [string]$Text = "",
    [string]$VoiceId = "CwhRBWXzGAHq8TQ4Fs17",
    [string]$Name = "audio_asset",
    [double]$Duration = 1.5,
    [string]$OutputDir = "assets/audio"
)

$ApiKey = $env:ELEVENLABS_API_KEY; if ([string]::IsNullOrWhiteSpace($ApiKey)) { throw "Defina a variavel de ambiente ELEVENLABS_API_KEY antes de executar este script." }
$BaseUrl = "https://api.elevenlabs.io/v1"
$Headers = @{
    "xi-api-key"   = $ApiKey
    "Content-Type" = "application/json"
}

function Get-Balance {
    Write-Host "[ElevenLabs] Consultando assinatura e limite de caracteres..." -ForegroundColor Cyan
    try {
        $sub = Invoke-RestMethod -Uri "$BaseUrl/user/subscription" -Headers $Headers -Method Get
        Write-Host "Plano: $($sub.tier)" -ForegroundColor Green
        Write-Host "Caracteres Usados: $($sub.character_count) / $($sub.character_limit)" -ForegroundColor Green
        Write-Host "Slots de Voz Usados: $($sub.voice_slots_used) / $($sub.voice_limit)" -ForegroundColor Green
        return $sub
    } catch {
        Write-Error "Erro ao consultar assinatura: $_"
    }
}

function Get-VoicesList {
    Write-Host "[ElevenLabs] Listando vozes disponíveis..." -ForegroundColor Cyan
    try {
        $res = Invoke-RestMethod -Uri "$BaseUrl/voices" -Headers $Headers -Method Get
        $res.voices | Select-Object -First 10 -Property voice_id, name, category | Format-Table -AutoSize
    } catch {
        Write-Error "Erro ao listar vozes: $_"
    }
}

function New-SoundEffect {
    param(
        [string]$PromptText,
        [string]$FileName,
        [double]$Seconds = 1.5,
        [string]$TargetFolder = "assets/audio/sfx"
    )

    if (-not (Test-Path $TargetFolder)) {
        New-Item -ItemType Directory -Force -Path $TargetFolder | Out-Null
    }

    Write-Host "[ElevenLabs] Gerando Efeito Sonoro (SFX): $FileName" -ForegroundColor Cyan
    Write-Host "Prompt: $PromptText (Duração: ${Seconds}s)" -ForegroundColor Gray

    $body = @{
        text             = $PromptText
        duration_seconds = $Seconds
    } | ConvertTo-Json

    $outPath = Join-Path $TargetFolder "$FileName.mp3"

    try {
        Invoke-RestMethod -Uri "$BaseUrl/sound-generation" -Headers $Headers -Method Post -Body $body -OutFile $outPath
        Write-Host "[ElevenLabs] SFX gerado com sucesso: $outPath" -ForegroundColor Green
    } catch {
        Write-Error "Erro ao gerar SFX: $_"
    }
}

function New-TextToSpeech {
    param(
        [string]$SpeechText,
        [string]$Voice,
        [string]$FileName,
        [string]$TargetFolder = "assets/audio/voices"
    )

    if (-not (Test-Path $TargetFolder)) {
        New-Item -ItemType Directory -Force -Path $TargetFolder | Out-Null
    }

    Write-Host "[ElevenLabs] Gerando Fala (TTS): $FileName" -ForegroundColor Cyan
    Write-Host "Texto: `"$SpeechText`"" -ForegroundColor Gray

    $body = @{
        text     = $SpeechText
        model_id = "eleven_multilingual_v2"
        voice_settings = @{
            stability        = 0.5
            similarity_boost = 0.75
        }
    } | ConvertTo-Json

    $outPath = Join-Path $TargetFolder "$FileName.mp3"

    try {
        Invoke-RestMethod -Uri "$BaseUrl/text-to-speech/$Voice" -Headers $Headers -Method Post -Body $body -OutFile $outPath
        Write-Host "[ElevenLabs] Fala gerada com sucesso: $outPath" -ForegroundColor Green
    } catch {
        Write-Error "Erro ao gerar TTS: $_"
    }
}

# Roteamento de comandos
switch ($Action.ToLower()) {
    "balance" {
        Get-Balance
    }
    "voices" {
        Get-VoicesList
    }
    "sfx" {
        if (-not $Text) {
            Write-Error "Informe o parâmetro -Text com a descrição do efeito sonoro."
            return
        }
        New-SoundEffect -PromptText $Text -FileName $Name -Seconds $Duration -TargetFolder $OutputDir
    }
    "tts" {
        if (-not $Text) {
            Write-Error "Informe o parâmetro -Text com o diálogo a ser dublado."
            return
        }
        New-TextToSpeech -SpeechText $Text -Voice $VoiceId -FileName $Name -TargetFolder $OutputDir
    }
    default {
        Write-Host "Ação desconhecida: $Action. Use 'balance', 'voices', 'sfx' ou 'tts'." -ForegroundColor Yellow
    }
}
