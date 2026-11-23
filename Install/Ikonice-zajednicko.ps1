# Definicije i pomocne funkcije za ikonice. Ucitava se posle Zajednicko.ps1.

$IcoDir     = Join-Path $IconsDir 'ICO'
$IconBackup = Join-Path $InstallRoot 'IconBackup'

# Stil ikonica: Bordo (Icons\ICO) ili Porcelan (Icons\Porcelan\ICO). Poslednji izbor se pamti,
# pa ga koriste i opcije bez izbora stila (npr. crvena "3" za sve fascikle).
$IconStyleFile = Join-Path $InstallRoot 'ikonice-stil.txt'
function Get-SavedIconStyle {
    if (Test-Path -LiteralPath $IconStyleFile) {
        $s = (Get-Content -LiteralPath $IconStyleFile -Raw).Trim()
        if ($s -eq 'Porcelan') { return 'Porcelan' }
    }
    return 'Bordo'
}
function Get-IcoDirForStyle([string]$Stil) {
    if ($Stil -eq 'Porcelan') { return (Join-Path $IconsDir 'Porcelan\ICO') }
    return (Join-Path $IconsDir 'ICO')
}

# Ista putanja nije dokaz da je ista i slika: nova izdanja menjaju ICO okvire.
# Poredimo pre kopiranja, da bi Explorer pri nadogradnji ponovo ucitao slike.
function Test-IconAssetsChanged([string]$SourceDirectory, [string]$DestinationDirectory) {
    foreach ($source in Get-ChildItem -LiteralPath $SourceDirectory -Filter '*.ico' -File) {
        $destination = Join-Path $DestinationDirectory $source.Name
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { return $true }
        if ((Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash) { return $true }
    }
    return $false
}
$KeyManifestPath    = Join-Path $IconBackup 'manifest.json'
$FolderManifestPath = Join-Path $IconBackup 'folder-icons.json'

$ExplorerClsid = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID'
# Provereno uzivo (Windows 11 26220): Directory/Folder/Drive\DefaultIcon u HKCU Explorer ignorise.
# Ostaju samo na listi za ciscenje starih instalacija (v1 ih je postavljao).
$LegacyIconKeys = @(
    'HKCU\Software\Classes\Directory\DefaultIcon'
    'HKCU\Software\Classes\Folder\DefaultIcon'
    'HKCU\Software\Classes\Drive\DefaultIcon'
)
$DriveIconRoot = 'HKCU\Software\Classes\Applications\Explorer.exe\Drives'

$IconRegistryTargets = @(
    # Ovaj racunar, Mreza, Korpa (navigacija u Explorer-u)
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\DefaultIcon'; Icon = 'ThisPC.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\DefaultIcon'; Icon = 'Network.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\DefaultIcon'; Icon = 'RecycleBin-Empty.ico'; Bin = $true }
    # Fascikle unutar "Ovaj racunar" (pravi shell CLSID-ovi, ne KNOWNFOLDERID)
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\DefaultIcon'; Icon = 'Desktop.ico' }
    # Home i Gallery u levoj navigaciji Windows 11 (na Windows 10 ovi kljucevi nemaju efekta)
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}\DefaultIcon'; Icon = 'Home.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\DefaultIcon'; Icon = 'Gallery.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{d3162b92-9365-467a-956b-92703aca08af}\DefaultIcon'; Icon = 'Folder-Documents.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{088e3905-0323-4b02-9826-5d99428e115f}\DefaultIcon'; Icon = 'Folder-Downloads.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}\DefaultIcon'; Icon = 'Folder-Pictures.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}\DefaultIcon'; Icon = 'Folder-Music.ico' }
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}\DefaultIcon'; Icon = 'Folder-Video.ico' }
    # Preuzimanja: poznata fascikla ima ParsingName shell:::{374DE290-...}, pa zakacena stavka u levoj
    # navigaciji uzima ikonicu iz ovog CLSID-a, a ne iz desktop.ini (provereno uzivo).
    [pscustomobject]@{ Key = 'HKCU\Software\Classes\CLSID\{374DE290-123F-4565-9164-39C4925E467B}\DefaultIcon'; Icon = 'Folder-Downloads.ico' }
    # Ikonice na radnoj povrsini (Explorer ih cuva posebno po korisniku)
    [pscustomobject]@{ Key = "$ExplorerClsid\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\DefaultIcon"; Icon = 'ThisPC.ico' }
    [pscustomobject]@{ Key = "$ExplorerClsid\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\DefaultIcon"; Icon = 'Network.ico' }
    [pscustomobject]@{ Key = "$ExplorerClsid\{645FF040-5081-101B-9F08-00AA002F954E}\DefaultIcon"; Icon = 'RecycleBin-Empty.ico'; Bin = $true }
    [pscustomobject]@{ Key = "$ExplorerClsid\{59031A47-3F72-44A7-89C5-5595FE6B30EE}\DefaultIcon"; Icon = 'User.ico' }
)

# DefaultIcon = originalna Windows ikonica, koristi se ako rezervna kopija desktop.ini ne postoji.
$KnownFolders = @(
    [pscustomobject]@{ RegistryValue = 'Desktop';                                Icon = 'Desktop.ico';          DefaultIcon = '%SystemRoot%\system32\imageres.dll,-183' }
    [pscustomobject]@{ RegistryValue = 'Personal';                              Icon = 'Folder-Documents.ico'; DefaultIcon = '%SystemRoot%\system32\imageres.dll,-112' }
    [pscustomobject]@{ RegistryValue = '{374DE290-123F-4565-9164-39C4925E467B}'; Icon = 'Folder-Downloads.ico'; DefaultIcon = '%SystemRoot%\system32\imageres.dll,-184' }
    [pscustomobject]@{ RegistryValue = 'My Pictures';                            Icon = 'Folder-Pictures.ico';  DefaultIcon = '%SystemRoot%\system32\imageres.dll,-113' }
    [pscustomobject]@{ RegistryValue = 'My Music';                               Icon = 'Folder-Music.ico';     DefaultIcon = '%SystemRoot%\system32\imageres.dll,-108' }
    [pscustomobject]@{ RegistryValue = 'My Video';                               Icon = 'Folder-Video.ico';     DefaultIcon = '%SystemRoot%\system32\imageres.dll,-189' }
)

# Ikonica diska po slovu (radi bez admin prava, provereno uzivo): lokalni i USB diskovi prisutni sada.
function Get-DriveIconTargets {
    Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
        Where-Object { $_.DriveType -in 2, 3 -and $_.DeviceID -match '^[A-Z]:$' } |
        ForEach-Object { [pscustomobject]@{ Key = "$DriveIconRoot\$($_.DeviceID.Substring(0,1))\DefaultIcon"; Icon = 'Drive.ico' } }
}

# Provereno uzivo (Windows 11 26220): zakacene stavke u levoj navigaciji (Quick access / Home)
# pamte ikonicu u trenutku kacenja i ne citaju je ponovo ni posle brisanja keša ikonica.
# Zato ih prekacujemo: od prve zakacene fascikle kojoj menjamo ikonicu do kraja liste,
# da bi redosled ostao isti. Windows izvrsava kacenje sa zakasnjenjem, pa svaki korak cekamo.
$QuickAccessTool = Join-Path $PSScriptRoot 'Brzi-pristup.ps1'

function Get-QuickAccessPins {
    return @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $QuickAccessTool -Lista | Where-Object { $_ })
}

# Promeni stanje kacenja i sacekaj da ga Windows potvrdi (do 40 s, uz jedan ponovni pokusaj).
function Set-Pin([string]$Path, [bool]$Pinned) {
    for ($try = 0; $try -lt 2; $try++) {
        if (((Get-QuickAccessPins) -contains $Path) -eq $Pinned) { return $true }
        & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $QuickAccessTool -Prekidac $Path
        for ($i = 0; $i -lt 20; $i++) {
            if (((Get-QuickAccessPins) -contains $Path) -eq $Pinned) { return $true }
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

function Update-QuickAccessPins([string[]]$ChangedFolders) {
    try {
        $pinned = @(Get-QuickAccessPins)
        if ($pinned.Count -eq 0) { return }   # Windows 10 / nema zakacenih stavki
        $changed = @($ChangedFolders | ForEach-Object { $_.TrimEnd('\').ToLowerInvariant() })
        $start = -1
        for ($i = 0; $i -lt $pinned.Count; $i++) { if ($changed -contains $pinned[$i].TrimEnd('\').ToLowerInvariant()) { $start = $i; break } }
        if ($start -lt 0) { return }
        $toRepin = @($pinned[$start..($pinned.Count - 1)])
        # Sigurnost: prekacujemo samo obicne fascikle na disku (ne korene diskova ni posebne stavke).
        foreach ($p in $toRepin) {
            if (-not ($p -match '^[A-Za-z]:\\.+' -and (Test-Path -LiteralPath $p -PathType Container))) {
                Write-Warning "Leva navigacija nije osvezena (posebna zakacena stavka: $p). Ikonice ce se videti kada fascikle ponovo zakacite."
                return
            }
        }
        # Jedna po jedna: otkaci -> potvrdi -> zakaci (ide na kraj) -> potvrdi. Posle cele liste redosled je isti.
        # Na prvu neuspelu potvrdu staje, da ne bi napravio nered u listi.
        Write-Host ("Osvezavam levu navigaciju Explorer-a ({0} zakacenih fascikli, do 1-2 minuta)..." -f $toRepin.Count)
        foreach ($p in $toRepin) {
            if (-not (Set-Pin $p $false)) { Write-Warning "Windows nije potvrdio otkacivanje: $p. Leva navigacija nije dalje menjana."; return }
            if (-not (Set-Pin $p $true)) {
                $rest = @($toRepin[([array]::IndexOf($toRepin, $p))..($toRepin.Count - 1)])
                Write-Warning ("Zakacite rucno (desni klik > Pin to Quick access), ovim redom: {0}" -f ($rest -join ', '))
                return
            }
        }
        Write-Host 'Leva navigacija je osvezena (iste zakacene fascikle, isti redosled).'
    } catch {
        Write-Warning ("Leva navigacija nije osvezena: {0}" -f $_.Exception.Message)
    }
}

# ---------- File Explorer na traci zadataka i u Start meniju ----------
# Zakacena precica nema putanju (cilj je shell objekat), pa je menjamo preko IShellLink
# (Shell.Application GetLink) koji cuva cilj; WScript.Shell bi ga mogao izgubiti.
# Rezervna kopija je ceo .lnk fajl, pa je vracanje bajt-za-bajt.
$ShortcutManifestPath = Join-Path $IconBackup 'shortcuts.json'
$ExplorerShortcutDirs = @(
    (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar')
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\System Tools')
)

function Get-ExplorerShortcuts {
    $shell = New-Object -ComObject Shell.Application
    foreach ($dir in $ExplorerShortcutDirs) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        $folder = $shell.Namespace($dir)
        foreach ($f in Get-ChildItem -LiteralPath $dir -Filter '*.lnk' -File) {
            try {
                $link = $folder.ParseName($f.Name).GetLink
                $iconPath = ''
                [void]$link.GetIconLocation([ref]$iconPath)
                if ($iconPath -match '\\explorer\.exe$|StudentiPobedili\\Icons\\(Porcelan\\)?ICO\\Explorer\.ico$' -or $link.Path -match '\\explorer\.exe$') {
                    [pscustomobject]@{ Path = $f.FullName; Link = $link }
                }
            } catch {}
        }
    }
}

function Set-ExplorerShortcutIcons {
    $records = @(Read-JsonRecords $ShortcutManifestPath 'Path')
    $icon = Join-Path $IcoDir 'Explorer.ico'
    $changed = 0
    foreach ($s in @(Get-ExplorerShortcuts)) {
        if (-not ($records | Where-Object { $_.Path -ieq $s.Path })) {
            $backup = New-BackupPath 'shortcut' 'lnk'
            Copy-Item -LiteralPath $s.Path -Destination $backup -Force
            $records += [pscustomobject]@{ Path = $s.Path; BackupFile = $backup }
            ConvertTo-Json -InputObject @($records) -Depth 3 | Set-Content -LiteralPath $ShortcutManifestPath -Encoding UTF8
        }
        $current = ''
        [void]$s.Link.GetIconLocation([ref]$current)
        if ($current -ieq $icon) { continue }   # vec postavljeno: bez nepotrebnog restarta
        $s.Link.SetIconLocation($icon, 0)
        $s.Link.Save()
        $changed++
    }
    return $changed
}

function Restore-ExplorerShortcutIcons {
    $restored = 0
    foreach ($r in @(Read-JsonRecords $ShortcutManifestPath 'Path')) {
        if ($r.BackupFile -and (Test-Path -LiteralPath $r.BackupFile) -and (Test-Path -LiteralPath (Split-Path -Parent $r.Path))) {
            Copy-Item -LiteralPath $r.BackupFile -Destination $r.Path -Force
            $restored++
        }
    }
    return $restored
}

# Traka zadataka cita ikonice precica samo pri pokretanju Explorer-a.
function Restart-ExplorerShell {
    try { & "$env:SystemRoot\System32\ie4uinit.exe" -show } catch {}
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    for ($i = 0; $i -lt 10 -and -not (Get-Process -Name explorer -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Start-Sleep -Seconds 3
}

function Get-KnownFolderPath([string]$RegistryValue) {
    $k = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders')
    if ($null -eq $k) { return $null }
    try { $raw = $k.GetValue($RegistryValue, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) } finally { $k.Dispose() }
    if ([string]::IsNullOrWhiteSpace([string]$raw)) { return $null }
    $p = [Environment]::ExpandEnvironmentVariables([string]$raw)
    if (-not (Test-Path -LiteralPath $p -PathType Container)) { Write-Warning "Preskacem nepostojecu fasciklu: $p"; return $null }
    return [System.IO.Path]::GetFullPath($p)
}

function New-BackupPath([string]$Prefix, [string]$Ext) {
    $i = 1
    do { $p = Join-Path $IconBackup ('{0}_{1:D2}.{2}' -f $Prefix, $i, $Ext); $i++ } while (Test-Path -LiteralPath $p)
    return $p
}

function Read-JsonRecords([string]$Path, [string]$Required) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $parsed = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $out = @()
    foreach ($c in @($parsed)) {
        if ($null -eq $c) { continue }
        if ($c.PSObject.Properties['Folders']) { $out += @($c.Folders) }
        elseif ($c.PSObject.Properties['value']) { $out += @($c.value) }
        else { $out += $c }
    }
    return @($out | Where-Object { $_ -and $_.PSObject.Properties[$Required] })
}
function Read-KeyManifest    { Read-JsonRecords $KeyManifestPath 'Key' }
function Read-FolderManifest { Read-JsonRecords $FolderManifestPath 'DesktopIniPath' }
function Save-KeyManifest($Records) {
    ConvertTo-Json -InputObject @($Records) -Depth 4 | Set-Content -LiteralPath $KeyManifestPath -Encoding UTF8
}
function Save-FolderManifest($Records) {
    ConvertTo-Json -InputObject ([pscustomobject]@{ Folders = @($Records) }) -Depth 6 | Set-Content -LiteralPath $FolderManifestPath -Encoding UTF8
}

# desktop.ini je obicno UTF-16 LE; citamo prema BOM-u da ne ostetimo LocalizedResourceName.
function Read-IniLines([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { $enc = [System.Text.Encoding]::Unicode }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { $enc = [System.Text.Encoding]::BigEndianUnicode }
    elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $enc = [System.Text.Encoding]::UTF8 }
    else { $enc = [System.Text.Encoding]::Default }
    $text = $enc.GetString($bytes).TrimStart([char]0xFEFF)
    return [string[]]($text -split "`r?`n")
}

# Postavlja samo klasicne atribute (ReadOnly, Hidden, System, Archive, Temporary, NotContentIndexed),
# a ostale bitove ostavlja kakvi su sada. OneDrive dodaje bitove (Pinned 0x80000, Unpinned 0x100000,
# RecallOnDataAccess...) koje .NET FileAttributes u Windows PowerShell 5.1 ne poznaje, pa bi obicna
# konverzija broja u [System.IO.FileAttributes] pukla, a menjanje tih bitova bi promenilo OneDrive podesavanje.
function Set-FileAttributesSafe([string]$Path, [int]$Value) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $classic = 0x1 -bor 0x2 -bor 0x4 -bor 0x20 -bor 0x100 -bor 0x2000
    $current = [int][System.IO.File]::GetAttributes($Path)
    $new = ($current -band (-bnot $classic)) -bor ($Value -band $classic)
    if (($new -band (-bnot 0x10)) -eq 0) { $new = $new -bor 0x80 }   # Normal kada nista drugo nije postavljeno
    [System.IO.File]::SetAttributes($Path, [Enum]::ToObject([System.IO.FileAttributes], $new))
}

function Clear-FileAttributes([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Set-FileAttributesSafe $Path 0 }
}

# Postavlja (ili sa $IconValue = $null uklanja) ikonicu u [.ShellClassInfo] sekciji.
function Set-DesktopIniIcon([string]$Path, [string]$IconValue) {
    $lines = New-Object 'System.Collections.Generic.List[string]'
    if (Test-Path -LiteralPath $Path) { foreach ($l in @(Read-IniLines $Path)) { $lines.Add([string]$l) } }
    while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
    $sec = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*\[\.ShellClassInfo\]\s*$') { $sec = $i; break } }
    if ($sec -lt 0) {
        if (-not $IconValue) { return }
        if ($lines.Count -gt 0) { $lines.Add('') }
        $lines.Add('[.ShellClassInfo]')
        $sec = $lines.Count - 1
    }
    $end = $lines.Count
    for ($i = $sec + 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*\[[^\]]+\]\s*$') { $end = $i; break } }
    for ($i = $end - 1; $i -gt $sec; $i--) {
        if ($lines[$i] -match '^\s*(IconResource|IconFile|IconIndex)\s*=') { $lines.RemoveAt($i); $end-- }
    }
    if ($IconValue) { $lines.Insert($sec + 1, "IconResource=$IconValue") }
    Clear-FileAttributes $Path
    [System.IO.File]::WriteAllLines($Path, $lines.ToArray(), [System.Text.Encoding]::Unicode)
    Set-FileAttributesSafe $Path 0x6   # Hidden + System
}
