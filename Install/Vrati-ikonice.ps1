# Vraca originalne Windows ikonice. Radi i sa rezervnim kopijama iz prve verzije paketa,
# ukljucujuci slucaj kada je rezervna kopija greskom sadrzala nase ikonice ili nedostaje.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Zajednicko.ps1')
. (Join-Path $PSScriptRoot 'Ikonice-zajednicko.ps1')

function Test-OurBackup([string]$File) {
    if (-not $File -or -not (Test-Path -LiteralPath $File)) { return $true }
    return [bool]((Get-Content -LiteralPath $File -Raw) -match 'StudentiPobedili')
}

try {
    $keyManifest = @(Read-KeyManifest)
    $folderManifest = @(Read-FolderManifest)
    if ($keyManifest.Count -eq 0 -and $folderManifest.Count -eq 0) {
        Write-Host 'Nema rezervne kopije - ikonice paketa verovatno nisu ni postavljene.' -ForegroundColor Yellow
    }

    # ---------- Registry ----------
    foreach ($item in $keyManifest) {
        $regPath = 'Registry::HKEY_CURRENT_USER\' + $item.Key.Substring(5)
        if (Test-Path -LiteralPath $regPath) { Invoke-Reg delete $item.Key /f }
        # Rezervna kopija koja sadrzi nase putanje nije original: brisanje kljuca vraca Windows podrazumevanu ikonicu.
        if ($item.Existed -and -not (Test-OurBackup $item.BackupFile)) { Invoke-Reg import $item.BackupFile }
    }
    # Dodatno ciscenje: bilo koji nas kljuc koji je ostao (npr. postavljen van manifesta)
    $driveKeys = @([char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ' | ForEach-Object { "$DriveIconRoot\$_\DefaultIcon" })
    foreach ($key in @($IconRegistryTargets | ForEach-Object { $_.Key }) + $LegacyIconKeys + $driveKeys) {
        $regPath = 'Registry::HKEY_CURRENT_USER\' + $key.Substring(5)
        if (Test-Path -LiteralPath $regPath) {
            $v = (Get-ItemProperty -LiteralPath $regPath -ErrorAction SilentlyContinue).'(default)'
            if ($v -and $v -match 'StudentiPobedili') { Invoke-Reg delete $key /f }
        }
    }
    # Prazni kljucevi Drives\<slovo> koje je napravio paket
    $drivesPath = 'Registry::HKEY_CURRENT_USER\' + $DriveIconRoot.Substring(5)
    if (Test-Path -LiteralPath $drivesPath) {
        Get-ChildItem -LiteralPath $drivesPath | Where-Object { $_.SubKeyCount -eq 0 -and $_.ValueCount -eq 0 } | Remove-Item -Force
        $d = Get-Item -LiteralPath $drivesPath
        if ($d.SubKeyCount -eq 0 -and $d.ValueCount -eq 0) { Remove-Item -LiteralPath $drivesPath -Force }
    }

    # ---------- desktop.ini ----------
    $knownByPath = @{}
    foreach ($kf in $KnownFolders) { $p = Get-KnownFolderPath $kf.RegistryValue; if ($p) { $knownByPath[$p.ToLowerInvariant()] = $kf } }
    $touched = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in $folderManifest) {
        $folder = [string]$item.FolderPath
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        $ini = [string]$item.DesktopIniPath
        $kf = $knownByPath[$folder.ToLowerInvariant()]
        if ($item.Existed -and $item.BackupFile -and (Test-Path -LiteralPath $item.BackupFile)) {
            Clear-FileAttributes $ini
            Copy-Item -LiteralPath $item.BackupFile -Destination $ini -Force
            if ($null -ne $item.DesktopIniAttributes) { Set-FileAttributesSafe $ini ([int64]$item.DesktopIniAttributes) }
        } elseif ($item.Existed) {
            # Rezervna kopija nedostaje: NE brisemo desktop.ini, vec vracamo originalnu Windows ikonicu.
            if ($kf) { Set-DesktopIniIcon -Path $ini -IconValue $kf.DefaultIcon } else { Set-DesktopIniIcon -Path $ini -IconValue $null }
        } elseif (Test-Path -LiteralPath $ini -PathType Leaf) {
            Set-DesktopIniIcon -Path $ini -IconValue $null
            $rest = @(@(Read-IniLines $ini) | Where-Object { $_.Trim() -and $_ -notmatch '^\s*\[\.ShellClassInfo\]\s*$' })
            if ($rest.Count -eq 0) { Clear-FileAttributes $ini; Remove-Item -LiteralPath $ini -Force }
        }
        if ($null -ne $item.FolderAttributes) { Set-FileAttributesSafe $folder ([int64]$item.FolderAttributes) }
        $touched.Add($folder)
    }

    # Precice File Explorer-a (traka zadataka, Start meni) - vraca se originalni .lnk fajl
    $shortcutsRestored = Restore-ExplorerShortcutIcons

    # Originalno stanje je vraceno; brisemo stare rezervne kopije da sledece postavljanje napravi ciste.
    if (Test-Path -LiteralPath $IconBackup) { Remove-Item -LiteralPath $IconBackup -Recurse -Force }

    Send-ShellRefresh $touched.ToArray()
    Update-QuickAccessPins $touched.ToArray()
    try { & "$env:SystemRoot\System32\ie4uinit.exe" -show } catch {}
    if (@($folderManifest | Where-Object { $_.Kind -eq 'Ordinary' }).Count -gt 0) {
        Restart-ExplorerWithFreshThumbnails
    } elseif ($shortcutsRestored -gt 0) {
        Write-Host 'Restartujem File Explorer da bi traka zadataka prikazala originalnu ikonicu...'
        Restart-ExplorerShell
    }
    Write-Host 'Originalne Windows ikonice su vracene.' -ForegroundColor Green
    Write-Host 'Ako neka ikonica ostane stara, ponovo pokrenite File Explorer ili se odjavite i prijavite.'
    exit 0
} catch {
    Write-Host ("GRESKA: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
