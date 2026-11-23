# Zajednicke putanje, definicije varijanti i pomocne funkcije.
# Ucitava se sa:  . (Join-Path $PSScriptRoot 'Zajednicko.ps1')

$Root        = $PSScriptRoot
$Package     = Split-Path -Parent $Root
$InstallRoot = Join-Path $env:LOCALAPPDATA 'StudentiPobedili'
$WallDir     = Join-Path $InstallRoot 'Wallpapers'
$LockDir     = Join-Path $InstallRoot 'LockScreen'
$IconsDir    = Join-Path $InstallRoot 'Icons'
$SoundsDir   = Join-Path $InstallRoot 'Sounds'
$BackupDir   = Join-Path $InstallRoot 'Backup'
$StateFile   = Join-Path $BackupDir 'stanje-pre-instalacije.json'
$ThemesDir   = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Themes'
$PersonalizeKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$DwmKey         = 'HKCU:\Software\Microsoft\Windows\DWM'
$ThemesKey      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes'

# Bordo #981F34 - za nijansu svetlija od brenda #7E0C26, tako da Windows-ove
# izvedene nijanse (tamnije za svetli rezim, svetlije za tamni) ostanu u bordo tonu.
# Kontrast prema beloj: 8.1:1 (WCAG AAA).
$AccentColor = '0XC4981F34'

# Slideshow: 16:9 pozadine sa srpskim zastavama. Ultrawide i tablet verzije su u Wallpapers za rucni izbor.
$Variants = @{
    Bordo = [pscustomobject]@{
        Key         = 'Bordo'
        DisplayName = 'Studenti pobedili - Bordo'
        FileName    = 'StudentiPobedili-Bordo.theme'
        PackName    = 'Studenti Pobedili Bordo'
        Mode        = 'Dark'
        Slideshow   = @('01-Pobeda-Cinematic-4K.jpg','03-Pobeda-Bordo-Talasi-4K.jpg','04-Beograd-4K.jpg')
    }
    Svetla = [pscustomobject]@{
        Key         = 'Svetla'
        DisplayName = 'Studenti pobedili - Svetla'
        FileName    = 'StudentiPobedili-Svetla.theme'
        PackName    = 'Studenti Pobedili Svetla'
        Mode        = 'Light'
        Slideshow   = @('02-Pobeda-Minimal-Light-4K.jpg')
    }
}

function New-ThemeText {
    param(
        [Parameter(Mandatory)]$Variant,
        [Parameter(Mandatory)][string[]]$WallpaperPaths,
        [Parameter(Mandatory)][string]$ImagesRoot,
        [string]$DisplayName = $Variant.DisplayName
    )
    $sb = New-Object System.Text.StringBuilder
    $add = { param($line) [void]$sb.AppendLine($line) }
    & $add '; Studenti pobedili - nezvanicna fan-made tema za Windows 10 / 11'
    & $add '; Menja samo pozadinu, akcentnu boju i tamni/svetli rezim.'
    & $add '; Kursori, zvukovi, cuvar ekrana i desktop ikonice ostaju kakvi jesu.'
    & $add ''
    & $add '[Theme]'
    & $add "DisplayName=$DisplayName"
    & $add 'SetLogonBackground=0'
    & $add ''
    & $add '[Control Panel\Desktop]'
    & $add "Wallpaper=$($WallpaperPaths[0])"
    & $add 'TileWallpaper=0'
    & $add 'WallpaperStyle=10'
    & $add 'Pattern='
    & $add ''
    & $add '[VisualStyles]'
    & $add 'Path=%ResourceDir%\Themes\Aero\Aero.msstyles'
    & $add 'ColorStyle=NormalColor'
    & $add 'Size=NormalSize'
    & $add 'AutoColorization=0'
    & $add "ColorizationColor=$AccentColor"
    & $add "SystemMode=$($Variant.Mode)"
    & $add "AppMode=$($Variant.Mode)"
    & $add ''
    & $add '[MasterThemeSelector]'
    & $add 'MTSM=RJSPBS'
    if ($WallpaperPaths.Count -gt 1) {
        & $add ''
        & $add '[Slideshow]'
        & $add 'Interval=1800000'
        & $add 'Shuffle=0'
        & $add "ImagesRootPath=$ImagesRoot"
        for ($i = 0; $i -lt $WallpaperPaths.Count; $i++) { & $add ("Item{0}Path={1}" -f $i, $WallpaperPaths[$i]) }
    }
    return $sb.ToString()
}

function Assert-Package {
    foreach ($d in 'Wallpapers','LockScreen','Icons\ICO','Icons\Porcelan\ICO','Sounds') {
        if (-not (Test-Path -LiteralPath (Join-Path $Package $d))) {
            throw "Nedostaje fascikla '$d'. Raspakujte CEO ZIP u novu fasciklu i pokrenite INSTALIRAJ.cmd odatle."
        }
    }
}

function Set-Dword([string]$Key, [string]$Name, [int]$Value) {
    if (-not (Test-Path -LiteralPath $Key)) { New-Item -Path $Key -Force | Out-Null }
    New-ItemProperty -Path $Key -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

# reg.exe pise "The operation completed successfully." na stderr; uz ErrorActionPreference=Stop
# PowerShell 5.1 to pretvara u gresku. Uspeh zato proveravamo iskljucivo po exit kodu.
function Invoke-Reg {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $out = & reg.exe @Arguments 2>&1 | Out-String } finally { $ErrorActionPreference = $old }
    if ($LASTEXITCODE -ne 0) { throw ("reg {0} nije uspeo: {1}" -f ($Arguments -join ' '), $out.Trim()) }
}

function Get-RegValue([string]$Key, [string]$Name) {
    $item = Get-ItemProperty -LiteralPath $Key -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $item) { return $null }
    return $item.$Name
}

function Test-OurTheme([string]$ThemePath) {
    if (-not $ThemePath) { return $false }
    if ($ThemePath -match 'StudentiPobedili|Studenti Pobedili') { return $true }
    $p = [Environment]::ExpandEnvironmentVariables($ThemePath)
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $false }
    return [bool]((Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue) -match 'DisplayName\s*=\s*Studenti pobedili|StudentiPobedili|Studenti Pobedili')
}

function Save-PreviousState {
    if (Test-Path -LiteralPath $StateFile) { return }
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    $current = Get-RegValue $ThemesKey 'CurrentTheme'
    if (Test-OurTheme $current) { $current = $null }
    $state = [pscustomobject]@{
        CurrentTheme         = $current
        AppsUseLightTheme    = Get-RegValue $PersonalizeKey 'AppsUseLightTheme'
        SystemUsesLightTheme = Get-RegValue $PersonalizeKey 'SystemUsesLightTheme'
        EnableTransparency   = Get-RegValue $PersonalizeKey 'EnableTransparency'
        TaskbarAccent        = Get-RegValue $PersonalizeKey 'ColorPrevalence'
        TitleBarAccent       = Get-RegValue $DwmKey 'ColorPrevalence'
    }
    $state | ConvertTo-Json | Set-Content -LiteralPath $StateFile -Encoding UTF8
}

function Close-Settings {
    $p = Get-Process -Name SystemSettings -ErrorAction SilentlyContinue
    if ($p) { $p | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 1500 }
}

function Invoke-Theme([string]$ThemeFile, [int]$TimeoutSeconds = 20) {
    # Provereno uzivo (Windows 11 26220): ako je Settings vec otvoren, Windows tiho ignorise .theme fajl.
    if (Get-Process -Name SystemSettings -ErrorAction SilentlyContinue) {
        Write-Host 'Zatvaram Settings da bi Windows mogao da primeni temu...'
        Close-Settings
    }
    $before = Get-RegValue $ThemesKey 'CurrentTheme'
    Start-Process -FilePath $ThemeFile
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $applied = $false
    Start-Sleep -Milliseconds 1500
    while ((Get-Date) -lt $deadline) {
        $now = Get-RegValue $ThemesKey 'CurrentTheme'
        if ($now -and ($now -ieq $ThemeFile)) {
            # Ako je ista tema vec bila aktivna, sacekaj da Windows zavrsi ponovno primenjivanje.
            if ($before -ieq $ThemeFile) { Start-Sleep -Seconds 2 }
            $applied = $true
            break
        }
        Start-Sleep -Milliseconds 500
    }
    # Windows otvara Settings prilikom aktiviranja teme; zatvaramo ga kad zavrsi.
    if ($applied) { Start-Sleep -Milliseconds 1200; Close-Settings }
    return $applied
}

function Initialize-Native {
    if ('StudentiPobedili.Native' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace StudentiPobedili {
public static class Native {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(uint action, uint param, string path, uint flags);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);
}}
'@
}

function Set-WallpaperDirect([string]$Path) {
    Initialize-Native
    if (-not [StudentiPobedili.Native]::SystemParametersInfo(20, 0, $Path, 3)) { throw 'Windows nije prihvatio postavljanje pozadine.' }
}

function Send-ColorRefresh {
    Initialize-Native
    $r = [UIntPtr]::Zero
    foreach ($topic in 'ImmersiveColorSet', 'WindowsThemeElement') {
        [void][StudentiPobedili.Native]::SendMessageTimeout([IntPtr]0xffff, 0x001A, [UIntPtr]::Zero, $topic, 0x0002, 1000, [ref]$r)
    }
}

function Send-ShellRefresh([string[]]$Folders = @()) {
    Initialize-Native
    [StudentiPobedili.Native]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    foreach ($f in $Folders) {
        if ($f -and (Test-Path -LiteralPath $f -PathType Container)) {
            $p = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($f)
            try { [StudentiPobedili.Native]::SHChangeNotify(0x00002000, 0x0005, $p, [IntPtr]::Zero) }
            finally { [System.Runtime.InteropServices.Marshal]::FreeHGlobal($p) }
        }
    }
}
