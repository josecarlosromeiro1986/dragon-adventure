Add-Type -AssemblyName System.Drawing
$files = Get-ChildItem "d:\projects\dragon-adventure\assets\sliced\*.png"
foreach ($f in $files) {
    if ($f.Name -notlike "*.import") {
        $img = [System.Drawing.Image]::FromFile($f.FullName)
        Write-Host "$($f.Name): $($img.Width)x$($img.Height)"
        $img.Dispose()
    }
}
