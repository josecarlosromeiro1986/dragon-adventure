param(
    [int]$Port = 8080,
    [switch]$SkipExport,
    [switch]$OpenBrowser = $true
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $ProjectRoot "build\web"

# Localizar executável do Godot 4.7.2
$GodotExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine*" -Recurse -Filter "*_console.exe" | Select-Object -First 1 -ExpandProperty FullName
if (-not $GodotExe) {
    $GodotExe = "godot"
}

if (-not $SkipExport) {
    if (-not (Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
    }
    Write-Host "[Godot 4] Exportando projeto para Web (HTML5 / WebGL2)..." -ForegroundColor Cyan
    & $GodotExe --headless --path $ProjectRoot --export-release "Web" "$BuildDir\index.html"
    Write-Host "[Godot 4] Exportação concluída em: $BuildDir\index.html" -ForegroundColor Green
}

# Localizar Google Chrome
$ChromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
$ChromeExe = $ChromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

$Url = "http://localhost:$Port/index.html"
Write-Host "[Servidor Web] Iniciando em $Url ..." -ForegroundColor Cyan

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:$Port/")
$Listener.Start()

if ($OpenBrowser -and $ChromeExe) {
    Write-Host "[Chrome] Abrindo navegador homologado: $ChromeExe" -ForegroundColor Yellow
    Start-Process -FilePath $ChromeExe -ArgumentList $Url
}

$MimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
    ".mp3"  = "audio/mpeg"
    ".wav"  = "audio/wav"
    ".ogg"  = "audio/ogg"
    ".json" = "application/json"
}

$BuildRootFull = [System.IO.Path]::GetFullPath($BuildDir).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
$AllowedOrigin = "http://localhost:$Port"

try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        try {
            $ReqPath = [System.Uri]::UnescapeDataString($Context.Request.Url.LocalPath).TrimStart('/', '\')
            if ([string]::IsNullOrEmpty($ReqPath)) { $ReqPath = "index.html" }

            $CandidatePath = Join-Path $BuildDir $ReqPath
            $FullPath = [System.IO.Path]::GetFullPath($CandidatePath)
            $IsInsideBuildDir = $FullPath.StartsWith($BuildRootFull, [System.StringComparison]::OrdinalIgnoreCase)

            if (-not $IsInsideBuildDir) {
                $Context.Response.StatusCode = 403
            } elseif (Test-Path $FullPath -PathType Leaf) {
                $Ext = [System.IO.Path]::GetExtension($FullPath).ToLower()
                $ContentType = if ($MimeTypes.ContainsKey($Ext)) { $MimeTypes[$Ext] } else { "application/octet-stream" }
                $Context.Response.ContentType = $ContentType
                $Context.Response.Headers.Add("Access-Control-Allow-Origin", $AllowedOrigin)
                $Context.Response.Headers.Add("Cache-Control", "no-cache")
                $Bytes = [System.IO.File]::ReadAllBytes($FullPath)
                $Context.Response.ContentLength64 = $Bytes.Length
                $Context.Response.StatusCode = 200
                $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
            } else {
                $Context.Response.StatusCode = 404
            }
            $Context.Response.OutputStream.Close()
        } catch {
            # Ignora conexões fechadas/abortadas pelo navegador durante reload ou resize
            try { $Context.Response.Abort() } catch {}
        }
    }
} finally {
    $Listener.Stop()
}
