# Uklanja sve sto je paket promenio i vraca prethodnu temu.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Zajednicko.ps1')

function Invoke-Child([string]$Script, [string[]]$Arguments = @()) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $Script) @Arguments
    if ($LASTEXITCODE -ne 0) {
        # Ne brisemo ikonice i rezervne kopije ako vracanje nije uspelo - inace bi Windows ostao sa pokvarenim putanjama.
        throw "$Script nije uspeo; deinstalacija je prekinuta, fajlovi paketa NISU obrisani. Pokusajte ponovo."
    }
}

try {
    # 1) Ikonice i zvuk
    if (Test-Path -LiteralPath (Join-Path $InstallRoot 'IconBackup')) { Invoke-Child 'Vrati-ikonice.ps1' }
    # Trazi UAC samo ako je ikonica svih fascikli zaista bila postavljena
    Invoke-Child 'Ikonica-svih-fascikli.ps1' @('-Vrati')
    Invoke-Child 'Zvuk.ps1' @('-Vrati')

    # 1b) Pozadine po virtuelnim desktopima koje pokazuju na fajlove paketa (inace ostane crna pozadina)
    $vd = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops\Desktops'
    if (Test-Path -LiteralPath $vd) {
        Get-ChildItem -LiteralPath $vd | ForEach-Object {
            $w = (Get-ItemProperty -LiteralPath $_.PSPath -Name Wallpaper -ErrorAction SilentlyContinue).Wallpaper
            if ($w -and $w -match 'StudentiPobedili') { Remove-ItemProperty -LiteralPath $_.PSPath -Name Wallpaper -ErrorAction SilentlyContinue }
        }
    }

    # 2) Prethodna tema i podesavanja boja
    $state = $null
    if (Test-Path -LiteralPath $StateFile) { $state = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json }
    $restore = @{
        AppsUseLightTheme = @($PersonalizeKey, 'AppsUseLightTheme', 1); SystemUsesLightTheme = @($PersonalizeKey, 'SystemUsesLightTheme', 0)
        EnableTransparency = @($PersonalizeKey, 'EnableTransparency', 1); TaskbarAccent = @($PersonalizeKey, 'ColorPrevalence', 0)
        TitleBarAccent = @($DwmKey, 'ColorPrevalence', 0)
    }
    foreach ($name in $restore.Keys) {
        $key, $value, $default = $restore[$name]
        $old = if ($state -and $null -ne $state.$name) { [int]$state.$name } else { $default }
        Set-Dword $key $value $old
    }
    $theme = if ($state -and $state.CurrentTheme -and (Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($state.CurrentTheme)))) {
        [Environment]::ExpandEnvironmentVariables($state.CurrentTheme)
    } else { Join-Path $env:SystemRoot 'Resources\Themes\aero.theme' }
    $current = Get-RegValue $ThemesKey 'CurrentTheme'
    if (Test-OurTheme $current) {
        Write-Host "Vracam prethodnu temu: $theme"
        [void](Invoke-Theme -ThemeFile $theme)
    }
    Send-ColorRefresh

    # 3) Brisanje fajlova paketa (samo nasi nazivi)
    Get-ChildItem -LiteralPath $ThemesDir -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'StudentiPobedili*' -or $_.Name -like 'Studenti Pobedili*' } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $InstallRoot) { Remove-Item -LiteralPath $InstallRoot -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host ''
    Write-Host 'Paket je uklonjen i prethodna tema je vracena.' -ForegroundColor Green
    Write-Host 'Zakljucani ekran promenite po zelji: Settings > Personalization > Lock screen.'
    exit 0
} catch {
    Write-Host ("GRESKA: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
