$json = Get-Content "assets/daniel_ragnar/anim_walk_improved/char_full.json" | ConvertFrom-Json
$anim = $json.animations | Where-Object { $_.animation_group_id -eq "e9194d2e-e8ee-49cd-96f9-ae2a18b51eed" }

$targetDir = "assets/daniel_ragnar/anim_walk"

# Limpar frames antigos
Get-ChildItem -Recurse $targetDir -Filter "*.png" | Remove-Item -Force
Get-ChildItem -Recurse $targetDir -Filter "*.import" | Remove-Item -Force

foreach ($d in $anim.directions) {
    $dirName = $d.direction
    $dirFolder = Join-Path $targetDir $dirName
    if (-not (Test-Path $dirFolder)) {
        New-Item -ItemType Directory -Force -Path $dirFolder | Out-Null
    }

    Write-Host "Baixando $($d.frames.Count) frames para $dirName..." -ForegroundColor Cyan
    $idx = 0
    foreach ($url in $d.frames) {
        $outPath = Join-Path $dirFolder "$idx.png"
        Invoke-WebRequest -Uri $url -OutFile $outPath
        Write-Host "  -> Salvo: $dirName/$idx.png" -ForegroundColor Green
        $idx++
    }
}

Write-Host "Todos os frames limpos da animação de caminhada foram instalados com sucesso!" -ForegroundColor Green
