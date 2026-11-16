$Token = $env:PIXELLAB_API_KEY; if ([string]::IsNullOrWhiteSpace($Token)) { throw "Defina a variavel de ambiente PIXELLAB_API_KEY antes de executar este script." }
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$CharId = "e3cc8aa7-f696-453f-b3d9-3809e52692d3"

$body = @{
    character_id = $CharId
    template_action = "walking"
} | ConvertTo-Json

try {
    $res = Invoke-WebRequest -Uri "https://api.pixellab.ai/v2/animate-character" -Headers $Headers -Method Post -Body $body
    $res.Content
} catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host "RESPOSTA 422:" ($reader.ReadToEnd())
}
