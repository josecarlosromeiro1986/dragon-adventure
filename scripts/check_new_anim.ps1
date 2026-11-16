Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("d:\projects\dragon-adventure\assets\daniel_ragnar\anim_walk\south\0.png")
Write-Host "Novo frame 0 South: $($img.Width)x$($img.Height)"
$img.Dispose()
