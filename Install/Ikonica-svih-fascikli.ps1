# Crvena fascikla "3" kao ikonica SVIH fascikli -> HKLM "Shell Icons" 3 i 4.
# Provereno uzivo (Windows 11 26220): Windows ovu ikonicu cita samo iz HKLM (HKCU varijanta nema
# efekta), pa su potrebna administratorska prava; vazi za sve korisnike racunara.
# (Leva navigacija NE zahteva HKLM: dovoljno je prekaciti stavke, to radi Postavi-ikonice.ps1.)
# Originalne vrednosti se cuvaju i vracaju sa -Vrati.
# -Stil Bordo | Porcelan; bez njega koristi se stil izabran za ostale ikonice (Postavi-ikonice.ps1).
param([switch]$Vrati, [string]$Log, [ValidateSet('', 'Bordo', 'Porcelan')][string]$Stil = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Zajednicko.ps1')
if (-not $Stil) {
    $styleFile = Join-Path $InstallRoot 'ikonice-stil.txt'
    $Stil = 'Bordo'
    if ((Test-Path -LiteralPath $styleFile) -and ((Get-Content -LiteralPath $styleFile -Raw).Trim() -eq 'Porcelan')) { $Stil = 'Porcelan' }
}
# Razlicito ime fajla po stilu: nova putanja tera Windows da ne koristi staru ikonicu iz kesa.
$StyleIconName = if ($Stil -eq 'Porcelan') { 'Folder-3-Porcelan.ico' } else { 'Folder-3.ico' }
$StyleIconSrc  = if ($Stil -eq 'Porcelan') { 'Icons\Porcelan\ICO\Folder-3.ico' } else { 'Icons\ICO\Folder-3.ico' }

$MachineDir    = Join-Path $env:ProgramData 'StudentiPobedili'
$BackupFile    = Join-Path $MachineDir 'shell-icons-backup.json'
$ShellIconsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
$FolderDescKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions'
$KnownFolderIcons = [ordered]@{
    '{FDD39AD0-238F-46AF-ADB4-6C85480369C7}' = 'Folder-Documents.ico'
    '{374DE290-123F-4565-9164-39C4925E467B}' = 'Folder-Downloads.ico'
    '{33E28130-4E1E-4676-835A-98395C3BC3BB}' = 'Folder-Pictures.ico'
    '{4BD8D571-6D19-48D3-BE97-422220080E43}' = 'Folder-Music.ico'
    '{18989B1D-99B5-455B-841C-AB7C74E4DDFC}' = 'Folder-Video.ico'
}

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Explorer {
    Write-Host 'Restartujem File Explorer da bi Windows ucitao ikonice...'
    try { & "$env:SystemRoot\System32\ie4uinit.exe" -ClearIconCache } catch {}
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    for ($i = 0; $i -lt 10 -and -not (Get-Process -Name explorer -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
}

# ---------- Bez admin prava: provera, UAC, restart Explorer-a (kao obican korisnik) ----------
if (-not (Test-Admin)) {
    if ($Vrati -and -not (Test-Path -LiteralPath $BackupFile)) {
        Write-Host 'Sistemske ikonice nisu menjane - nema sta da se vrati.'
        exit 0
    }
    if (-not $Vrati) { Assert-Package }
    Write-Host 'Potrebna su administratorska prava: potvrdite Windows prozor (UAC).' -ForegroundColor Yellow
    $logFile = Join-Path ([IO.Path]::GetTempPath()) ('StudentiPobedili-admin-{0}.log' -f [guid]::NewGuid().ToString('N'))
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath), '-Log', ('"{0}"' -f $logFile), '-Stil', $Stil)
    if ($Vrati) { $argList += '-Vrati' }
    try {
        $p = Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $argList -WindowStyle Hidden -Wait -PassThru
    } catch {
        Write-Host 'Administratorska potvrda je odbijena - nista nije promenjeno.' -ForegroundColor Yellow
        exit 2
    }
    if (Test-Path -LiteralPath $logFile) { Get-Content -LiteralPath $logFile | Write-Host; Remove-Item -LiteralPath $logFile -Force }
    if ($p.ExitCode -ne 0) { exit $p.ExitCode }
    Restart-Explorer
    exit 0
}

# ---------- Sa admin pravima ----------
function Write-Log([string]$Text) { if ($Log) { Add-Content -LiteralPath $Log -Value $Text -Encoding UTF8 } else { Write-Host $Text } }

function Read-Backup {
    if (-not (Test-Path -LiteralPath $BackupFile)) { return $null }
    return Get-Content -LiteralPath $BackupFile -Raw | ConvertFrom-Json
}

function Restore-Value([string]$Key, [string]$Name, $Record) {
    if ($null -eq $Record) { return }
    if ($Record.Existed) {
        if (-not (Test-Path -LiteralPath $Key)) { New-Item -Path $Key -Force | Out-Null }
        Set-ItemProperty -LiteralPath $Key -Name $Name -Value ([string]$Record.Value)
    } elseif (Test-Path -LiteralPath $Key) {
        Remove-ItemProperty -LiteralPath $Key -Name $Name -ErrorAction SilentlyContinue
    }
}

function New-Record([string]$Key, [string]$Name) {
    $v = if (Test-Path -LiteralPath $Key) { Get-RegValue $Key $Name } else { $null }
    if ($v -and $v -match 'StudentiPobedili') { $v = $null }   # nasa vrednost nije original
    return [pscustomobject]@{ Existed = ($null -ne $v); Value = $v }
}

try {
    $backup = Read-Backup

    if ($Vrati) {
        if ($backup) {
            Restore-Value $ShellIconsKey '3' $backup.'3'
            Restore-Value $ShellIconsKey '4' $backup.'4'
            if (-not $backup.KeyExisted -and (Test-Path -LiteralPath $ShellIconsKey)) {
                $k = Get-Item -LiteralPath $ShellIconsKey
                if ($k.ValueCount -eq 0 -and $k.SubKeyCount -eq 0) { Remove-Item -LiteralPath $ShellIconsKey -Force }
            }
            if ($backup.PSObject.Properties['KnownFolders']) {
                foreach ($id in $KnownFolderIcons.Keys) {
                    $rec = $backup.KnownFolders.$id
                    if ($rec) { Restore-Value (Join-Path $FolderDescKey $id) 'Icon' $rec }
                }
            }
        }
        if (Test-Path -LiteralPath $MachineDir) { Remove-Item -LiteralPath $MachineDir -Recurse -Force }
        Write-Log 'Vracene su originalne Windows ikonice fascikli i leve navigacije.'
        exit 0
    }

    New-Item -ItemType Directory -Path $MachineDir -Force | Out-Null
    $folderIcon = Join-Path $MachineDir $StyleIconName
    Copy-Item -LiteralPath (Join-Path $Package $StyleIconSrc) -Destination $folderIcon -Force

    if (-not $backup) {
        $backup = [pscustomobject]@{
            KeyExisted = (Test-Path -LiteralPath $ShellIconsKey)
            '3' = New-Record $ShellIconsKey '3'
            '4' = New-Record $ShellIconsKey '4'
        }
    }
    # Ciscenje razvojne verzije koja je menjala i FolderDescriptions: vracamo original i brisemo zapis.
    if ($backup.PSObject.Properties['KnownFolders']) {
        foreach ($id in $KnownFolderIcons.Keys) {
            $rec = $backup.KnownFolders.$id
            if ($rec) { Restore-Value (Join-Path $FolderDescKey $id) 'Icon' $rec }
        }
        $backup.PSObject.Properties.Remove('KnownFolders')
        Get-ChildItem -LiteralPath $MachineDir -Filter 'Folder-*.ico' | Where-Object { $_.Name -notmatch '^Folder-3(-Porcelan)?\.ico$' } | Remove-Item -Force
    }
    $backup | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BackupFile -Encoding UTF8

    if (-not (Test-Path -LiteralPath $ShellIconsKey)) { New-Item -Path $ShellIconsKey -Force | Out-Null }
    foreach ($n in '3', '4') { Set-ItemProperty -LiteralPath $ShellIconsKey -Name $n -Value "$folderIcon,0" }
    # Ikonica drugog stila vise nije u upotrebi (Explorer se restartuje odmah posle ovoga).
    Get-ChildItem -LiteralPath $MachineDir -Filter 'Folder-3*.ico' | Where-Object { $_.Name -ne $StyleIconName } |
        ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Force } catch {} }
    Write-Log ('Fascikla "3" ({0}) je postavljena za sve fascikle.' -f $Stil)
    exit 0
} catch {
    Write-Log ("GRESKA: {0}" -f $_.Exception.Message)
    exit 1
}
