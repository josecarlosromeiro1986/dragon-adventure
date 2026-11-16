$json = Get-Content "assets/daniel_ragnar/anim_walk_improved/char_full.json" | ConvertFrom-Json
$anim = $json.animations | Where-Object { $_.animation_group_id -eq "e9194d2e-e8ee-49cd-96f9-ae2a18b51eed" }
Write-Host "Animation Type: $($anim.animation_type)"
Write-Host "Directions count: $($anim.directions.Count)"
foreach ($d in $anim.directions) {
    Write-Host "Direction: $($d.direction)"
    Write-Host "Keys in direction object: $($d | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)"
    if ($d.frames) {
        Write-Host "Frames count: $($d.frames.Count)"
        Write-Host "First frame: $($d.frames[0] | ConvertTo-Json -Compress)"
    }
}
