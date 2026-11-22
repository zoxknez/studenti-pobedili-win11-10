# Studenti pobedili - instalacija teme za Windows 10 / 11 (samo trenutni korisnik, bez admin prava)
param(
    [ValidateSet('Bordo','Svetla')][string]$Stil = 'Bordo'
)
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Zajednicko.ps1')

try {
    Assert-Package

    # 1) Kopiranje sadrzaja u korisnicki profil
    foreach ($d in @($WallDir,$LockDir,$IconsDir,$SoundsDir,$ThemesDir,$BackupDir)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    # stare pozadine iz prethodnih verzija se brisu, da ne ostanu u fascikli slideshow-a
    Get-ChildItem -LiteralPath $WallDir -Filter *.jpg -File -ErrorAction SilentlyContinue | Remove-Item -Force
    Copy-Item -Path (Join-Path $Package 'Wallpapers\*') -Destination $WallDir -Force
    Copy-Item -Path (Join-Path $Package 'LockScreen\*') -Destination $LockDir -Force
    Copy-Item -Path (Join-Path $Package 'Icons\*') -Destination $IconsDir -Recurse -Force
    Copy-Item -Path (Join-Path $Package 'Sounds\*') -Destination $SoundsDir -Force
    Get-ChildItem -Path $InstallRoot -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

    # 2) Pamtimo prethodno stanje (samo pri prvoj instalaciji) radi deinstalacije
    Save-PreviousState

    # 3) Pravljenje .theme fajla u Windows 11 formatu
    $v = $Variants[$Stil]
    $items = @($v.Slideshow | ForEach-Object { Join-Path $WallDir $_ })
    foreach ($p in $items) { if (-not (Test-Path -LiteralPath $p)) { throw "Nedostaje pozadina: $p" } }
    $themeText = New-ThemeText -Variant $v -WallpaperPaths $items -ImagesRoot $WallDir
    $themeFile = Join-Path $ThemesDir $v.FileName
    [System.IO.File]::WriteAllText($themeFile, $themeText, [System.Text.Encoding]::Unicode)

    # 4) Podesavanja koja .theme fajl ne moze da nosi (trenutni korisnik)
    $light = [int]($Stil -eq 'Svetla')
    Set-Dword $PersonalizeKey 'AppsUseLightTheme'    $light
    Set-Dword $PersonalizeKey 'SystemUsesLightTheme' $light
    Set-Dword $PersonalizeKey 'EnableTransparency'   1
    # Akcentna boja na Start meniju i traci zadataka (Windows to dozvoljava samo u tamnom rezimu)
    Set-Dword $PersonalizeKey 'ColorPrevalence'      ([int]($Stil -eq 'Bordo'))
    # Akcentna boja na naslovnim trakama i ivicama prozora
    Set-Dword $DwmKey 'ColorPrevalence' 1

    # 5) Aktiviranje teme. Provereno uzivo: Windows pri primeni teme resetuje zvuk obavestenja,
    #    pa ukljuceni zvuk "Pobeda" pamtimo i vracamo posle primene.
    $soundKey = 'HKCU:\AppEvents\Schemes\Apps\.Default\Notification.Default\.Current'
    $soundBefore = $null
    if (Test-Path -LiteralPath $soundKey) { $soundBefore = (Get-ItemProperty -LiteralPath $soundKey).'(default)' }
    $applied = Invoke-Theme -ThemeFile $themeFile
    if ($soundBefore -and $soundBefore -match 'StudentiPobedili') {
        Start-Sleep -Seconds 1
        Set-ItemProperty -LiteralPath $soundKey -Name '(default)' -Value $soundBefore
    }
    if (-not $applied) {
        Write-Warning 'Windows nije potvrdio aktiviranje teme na vreme; postavljam pozadinu direktno.'
        Set-WallpaperDirect $items[0]
    }
    Send-ColorRefresh

    Write-Host ''
    Write-Host ("Tema je instalirana: {0}" -f $v.DisplayName) -ForegroundColor Green
    Write-Host ("Pozadine se smenjuju svakih 30 minuta ({0} slike). Promena: Settings > Personalization > Background." -f $items.Count)
    Write-Host ("Sve pozadine: {0}" -f $WallDir)
    exit 0
} catch {
    Write-Host ("GRESKA: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
