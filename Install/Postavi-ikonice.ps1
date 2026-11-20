# Postavlja prilagodjene ikonice za trenutnog korisnika (HKCU + desktop.ini), uz rezervnu kopiju.
# Bezbedno je pokrenuti vise puta: rezervna kopija se pravi SAMO od originalnog (ne nase) stanja.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Zajednicko.ps1')
. (Join-Path $PSScriptRoot 'Ikonice-zajednicko.ps1')

try {
    Assert-Package
    New-Item -ItemType Directory -Path $IcoDir -Force | Out-Null
    New-Item -ItemType Directory -Path $IconBackup -Force | Out-Null
    Copy-Item -Path (Join-Path $Package 'Icons\ICO\*') -Destination $IcoDir -Force
    Copy-Item -Path (Join-Path $Package 'Icons\PNG') -Destination $IconsDir -Recurse -Force

    # ---------- Registry ----------
    $manifest = @(Read-KeyManifest)
    # Stari kljucevi koje Windows 11 ignorise: ako ih je postavila prethodna verzija, uklanjamo ih.
    foreach ($k in $LegacyIconKeys) {
        $p = 'Registry::HKEY_CURRENT_USER\' + $k.Substring(5)
        if ((Test-Path -LiteralPath $p) -and ((Get-ItemProperty -LiteralPath $p -ErrorAction SilentlyContinue).'(default)' -match 'StudentiPobedili')) {
            Invoke-Reg delete $k /f   # original (ako ga je bilo) vraca Vrati-ikonice iz manifesta
        }
    }
    foreach ($t in @($IconRegistryTargets) + @(Get-DriveIconTargets)) {
        if (-not ($manifest | Where-Object { $_.Key -ieq $t.Key })) {
            $regPath = 'Registry::HKEY_CURRENT_USER\' + $t.Key.Substring(5)
            $existed = $false
            $backupFile = ''
            if (Test-Path -LiteralPath $regPath) {
                $current = (Get-ItemProperty -LiteralPath $regPath -ErrorAction SilentlyContinue).'(default)'
                # Vrednost koja vec pokazuje na nase ikonice nije "original" - ne cuvamo je.
                if (-not ($current -and $current -match 'StudentiPobedili')) {
                    $existed = $true
                    $backupFile = New-BackupPath 'key' 'reg'
                    Invoke-Reg export $t.Key $backupFile /y
                }
            }
            $manifest += [pscustomobject]@{ Key = $t.Key; Existed = $existed; BackupFile = $backupFile }
            Save-KeyManifest $manifest
        }
        Invoke-Reg add $t.Key /ve /t REG_SZ /d ('{0},0' -f (Join-Path $IcoDir $t.Icon)) /f
        if ($t.Bin) {
            Invoke-Reg add $t.Key /v Empty /t REG_SZ /d ('{0},0' -f (Join-Path $IcoDir 'RecycleBin-Empty.ico')) /f
            Invoke-Reg add $t.Key /v Full  /t REG_SZ /d ('{0},0' -f (Join-Path $IcoDir 'RecycleBin-Full.ico'))  /f
        }
    }

    # ---------- desktop.ini standardnih korisnickih fascikli ----------
    $folderManifest = @(Read-FolderManifest)
    $touched = New-Object 'System.Collections.Generic.List[string]'
    foreach ($kf in $KnownFolders) {
        $folderPath = Get-KnownFolderPath $kf.RegistryValue
        if (-not $folderPath) { continue }
        $iniPath = Join-Path $folderPath 'desktop.ini'
        $record = $folderManifest | Where-Object { $_.DesktopIniPath -ieq $iniPath } | Select-Object -First 1
        if ($null -eq $record) {
            $iniExisted = Test-Path -LiteralPath $iniPath -PathType Leaf
            $backupFile = ''
            $iniAttr = $null
            if ($iniExisted) {
                $iniAttr = [int][System.IO.File]::GetAttributes($iniPath)
                $backupFile = New-BackupPath 'desktop' 'ini'
                Copy-Item -LiteralPath $iniPath -Destination $backupFile -Force
            }
            $folderManifest += [pscustomobject]@{
                FolderPath = $folderPath; DesktopIniPath = $iniPath; Existed = $iniExisted
                BackupFile = $backupFile; FolderAttributes = [int][System.IO.File]::GetAttributes($folderPath)
                DesktopIniAttributes = $iniAttr
            }
            Save-FolderManifest $folderManifest
        }
        # ReadOnly atribut na fascikli je uslov da Explorer procita desktop.ini
        $fa = [System.IO.File]::GetAttributes($folderPath)
        if (($fa -band [System.IO.FileAttributes]::ReadOnly) -eq 0) { [System.IO.File]::SetAttributes($folderPath, $fa -bor [System.IO.FileAttributes]::ReadOnly) }
        Set-DesktopIniIcon -Path $iniPath -IconValue ('{0},0' -f (Join-Path $IcoDir $kf.Icon))
        $touched.Add($folderPath)
    }

    Send-ShellRefresh $touched.ToArray()
    try { & "$env:SystemRoot\System32\ie4uinit.exe" -show } catch {}
    Update-QuickAccessPins $touched.ToArray()
    # File Explorer na traci zadataka i u Start meniju; traka ga ucitava tek posle restarta Explorer-a.
    if ((Set-ExplorerShortcutIcons) -gt 0) {
        Write-Host 'Restartujem File Explorer da bi traka zadataka prikazala novu ikonicu...'
        Restart-ExplorerShell
    }
    Write-Host 'Prilagodjene ikonice su postavljene za trenutnog Windows korisnika.' -ForegroundColor Green
    Write-Host 'Ako neka ikonica ostane stara, ponovo pokrenite File Explorer ili se odjavite i prijavite.'
    exit 0
} catch {
    Write-Host ("GRESKA: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
