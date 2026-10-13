param(
    [string]$SourcePath = "C:\Users\USER\.gemini\antigravity-ide\brain\b66eba80-acc2-40f2-bd9a-fe8006acd69d\aquaguard_app_icon_1791872345094.jpg",
    [string]$RootDir = "e:\Workshops\IOT\mobile_app"
)

Add-Type -AssemblyName System.Drawing

$srcImage = [System.Drawing.Image]::FromFile($SourcePath)

function Resize-And-Save {
    param(
        [System.Drawing.Image]$Image,
        [int]$Width,
        [int]$Height,
        [string]$DestinationPath,
        [bool]$NoAlpha = $false
    )

    $format = if ($NoAlpha) { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)
    $destImage = New-Object System.Drawing.Bitmap($Width, $Height, $format)

    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $wrapMode = New-Object System.Drawing.Imaging.ImageAttributes
    $wrapMode.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $graphics.DrawImage($Image, $destRect, 0, 0, $Image.Width, $Image.Height, [System.Drawing.GraphicsUnit]::Pixel, $wrapMode)
    $graphics.Dispose()
    $wrapMode.Dispose()

    $dir = [System.IO.Path]::GetDirectoryName($DestinationPath)
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $destImage.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destImage.Dispose()
    Write-Host "Generated: $DestinationPath ($Width x $Height)"
}

$webTargets = @("web", "mobile_app\web")

foreach ($wt in $webTargets) {
    $base = Join-Path $RootDir $wt
    Resize-And-Save -Image $srcImage -Width 512 -Height 512 -DestinationPath (Join-Path $base "icons\Icon-512.png")
    Resize-And-Save -Image $srcImage -Width 192 -Height 192 -DestinationPath (Join-Path $base "icons\Icon-192.png")
    Resize-And-Save -Image $srcImage -Width 512 -Height 512 -DestinationPath (Join-Path $base "icons\Icon-maskable-512.png")
    Resize-And-Save -Image $srcImage -Width 192 -Height 192 -DestinationPath (Join-Path $base "icons\Icon-maskable-192.png")
    Resize-And-Save -Image $srcImage -Width 180 -Height 180 -DestinationPath (Join-Path $base "icons\apple-touch-icon.png")
    Resize-And-Save -Image $srcImage -Width 64 -Height 64 -DestinationPath (Join-Path $base "favicon.png")
}

$iosTargets = @(
    "ios\Runner\Assets.xcassets\AppIcon.appiconset",
    "mobile_app\ios\Runner\Assets.xcassets\AppIcon.appiconset"
)

$iosSizes = @(
    @{ Name = "Icon-App-1024x1024@1x.png"; Width = 1024; Height = 1024 },
    @{ Name = "Icon-App-83.5x83.5@2x.png"; Width = 167; Height = 167 },
    @{ Name = "Icon-App-76x76@2x.png"; Width = 152; Height = 152 },
    @{ Name = "Icon-App-76x76@1x.png"; Width = 76; Height = 76 },
    @{ Name = "Icon-App-60x60@3x.png"; Width = 180; Height = 180 },
    @{ Name = "Icon-App-60x60@2x.png"; Width = 120; Height = 120 },
    @{ Name = "Icon-App-40x40@3x.png"; Width = 120; Height = 120 },
    @{ Name = "Icon-App-40x40@2x.png"; Width = 80; Height = 80 },
    @{ Name = "Icon-App-40x40@1x.png"; Width = 40; Height = 40 },
    @{ Name = "Icon-App-29x29@3x.png"; Width = 87; Height = 87 },
    @{ Name = "Icon-App-29x29@2x.png"; Width = 58; Height = 58 },
    @{ Name = "Icon-App-29x29@1x.png"; Width = 29; Height = 29 },
    @{ Name = "Icon-App-20x20@3x.png"; Width = 60; Height = 60 },
    @{ Name = "Icon-App-20x20@2x.png"; Width = 40; Height = 40 },
    @{ Name = "Icon-App-20x20@1x.png"; Width = 20; Height = 20 }
)

foreach ($it in $iosTargets) {
    $base = Join-Path $RootDir $it
    if (Test-Path $base) {
        foreach ($sz in $iosSizes) {
            $isMarketing1024 = ($sz.Width -eq 1024)
            Resize-And-Save -Image $srcImage -Width $sz.Width -Height $sz.Height -DestinationPath (Join-Path $base $sz.Name) -NoAlpha $isMarketing1024
        }
    }
}

$androidTargets = @(
    "android\app\src\main\res",
    "mobile_app\android\app\src\main\res"
)

$androidSizes = @(
    @{ Folder = "mipmap-mdpi"; Size = 48 },
    @{ Folder = "mipmap-hdpi"; Size = 72 },
    @{ Folder = "mipmap-xhdpi"; Size = 96 },
    @{ Folder = "mipmap-xxhdpi"; Size = 144 },
    @{ Folder = "mipmap-xxxhdpi"; Size = 192 }
)

foreach ($at in $androidTargets) {
    $base = Join-Path $RootDir $at
    if (Test-Path $base) {
        foreach ($sz in $androidSizes) {
            $dest = Join-Path (Join-Path $base $sz.Folder) "ic_launcher.png"
            Resize-And-Save -Image $srcImage -Width $sz.Size -Height $sz.Size -DestinationPath $dest
        }
    }
}

$srcImage.Dispose()
Write-Host "All icons generated successfully!"
