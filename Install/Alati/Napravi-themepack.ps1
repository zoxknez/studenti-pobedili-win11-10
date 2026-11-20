# Pravi .deskthemepack fajlove (Windows 10/11 native paket teme: dvoklik = instalacija).
# Pokretanje:  powershell -NoProfile -ExecutionPolicy Bypass -File Install\Alati\Napravi-themepack.ps1
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'Zajednicko.ps1')

$outDir = Join-Path $Package 'Teme'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

foreach ($v in $Variants.Values) {
    $stage = Join-Path ([System.IO.Path]::GetTempPath()) ("sp-themepack-" + $v.Key)
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    New-Item -ItemType Directory -Path $stage | Out-Null

    # Provereno uzivo (Windows 11 26220): Windows raspakuje paket u
    # %LOCALAPPDATA%\Microsoft\Windows\Themes\<ime unutrasnjeg .theme fajla bez ekstenzije>\DesktopBackground
    # (ne po imenu .deskthemepack fajla niti po DisplayName), pa putanje gradimo po tom imenu.
    $bgRoot = '%USERPROFILE%\AppData\Local\Microsoft\Windows\Themes\' + [System.IO.Path]::GetFileNameWithoutExtension($v.FileName) + '\DesktopBackground'
    $paths = @($v.Slideshow | ForEach-Object { "$bgRoot\$_" })
    $themeText = New-ThemeText -Variant $v -WallpaperPaths $paths -ImagesRoot $bgRoot -DisplayName $v.PackName
    $themeName = $v.FileName
    [System.IO.File]::WriteAllText((Join-Path $stage $themeName), $themeText, [System.Text.Encoding]::Unicode)

    $ddf = New-Object System.Text.StringBuilder
    foreach ($line in @(
        '.OPTION EXPLICIT', '.Set CabinetNameTemplate=pack.cab', ".Set DiskDirectoryTemplate=$stage",
        '.Set Cabinet=on', '.Set Compress=on', '.Set CompressionType=MSZIP', '.Set MaxDiskSize=0',
        '.Set RptFileName=NUL', '.Set InfFileName=NUL', '.Set DestinationDir=',
        ('"{0}" "{1}"' -f (Join-Path $stage $themeName), $themeName),
        '.Set DestinationDir=DesktopBackground')) { [void]$ddf.AppendLine($line) }
    foreach ($img in $v.Slideshow) {
        $src = Join-Path $Package "Wallpapers\$img"
        if (-not (Test-Path -LiteralPath $src)) { throw "Nedostaje pozadina: $src" }
        [void]$ddf.AppendLine(('"{0}" "{1}"' -f $src, $img))
    }
    $ddfPath = Join-Path $stage 'pack.ddf'
    [System.IO.File]::WriteAllText($ddfPath, $ddf.ToString(), [System.Text.Encoding]::ASCII)

    & makecab.exe /F $ddfPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "makecab nije uspeo za $($v.PackName)" }
    $target = Join-Path $outDir ($v.PackName + '.deskthemepack')
    Move-Item -LiteralPath (Join-Path $stage 'pack.cab') -Destination $target -Force
    Remove-Item -LiteralPath $stage -Recurse -Force
    Write-Host ("Napravljen: {0} ({1:N1} MB)" -f $target, ((Get-Item $target).Length / 1MB)) -ForegroundColor Green
}
