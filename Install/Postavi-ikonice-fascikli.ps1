# Pojedinacna ikonica sprecava zuti Windows okvir u velikom prikazu fascikle.
# Bez argumenata: bira se lokacija cije neposredne potfascikle treba promeniti.
# Primer: -Putanja 'D:\' -Potfascikle -Stil Porcelan
# Bez -Potfascikle menja samo navedenu fasciklu; ne obilazi stablo diska.
param(
    [string]$Putanja,
    [switch]$Potfascikle,
    [ValidateSet('', 'Bordo', 'Porcelan')][string]$Stil = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Zajednicko.ps1')
. (Join-Path $PSScriptRoot 'Ikonice-zajednicko.ps1')

try {
    Assert-Package
    if (-not $Putanja) {
        Write-Host 'Ikonica fascikle u svim velicinama (Small, Medium, Large, Extra large).'
        Write-Host 'Menja samo neposredne potfascikle unete lokacije, uz rezervnu kopiju.'
        Write-Host 'Postojece tudje ikonice se preskacu. Pregledi slika i videa ostaju ukljuceni.'
        $Putanja = (Read-Host 'Lokacija (npr. D:\ ili D:\Slike; Enter = odustani)').Trim().Trim('"')
        if (-not $Putanja) { exit 0 }
        $Potfascikle = $true
    }
    $location = Get-Item -LiteralPath $Putanja -Force
    if (-not $location.PSIsContainer -or $location.PSProvider.Name -ne 'FileSystem') { throw 'Unesite postojecu fasciklu na disku.' }
    $path = $location.FullName
    if (($location.Attributes -band 0x400) -ne 0) { throw 'Izaberite stvarnu fasciklu, ne vezu (junction/symlink).' }
    if (-not $Potfascikle -and $path.TrimEnd('\') -eq [IO.Path]::GetPathRoot($path).TrimEnd('\')) {
        throw 'Za koren diska koristite -Potfascikle; ikonica samog diska se ovde ne menja.'
    }
    if (-not $Stil) { $Stil = Get-SavedIconStyle }
    $IcoDir = Get-IcoDirForStyle $Stil
    New-Item -ItemType Directory -Path $IcoDir,$IconBackup -Force | Out-Null
    $icon = Join-Path $IcoDir 'Folder-3.ico'
    $source = Join-Path (Join-Path $Package $(if ($Stil -eq 'Porcelan') { 'Icons\Porcelan\ICO' } else { 'Icons\ICO' })) 'Folder-3.ico'
    Copy-Item -LiteralPath $source -Destination $icon -Force
    $targets = if ($Potfascikle) { @(Get-ChildItem -LiteralPath $path -Directory -Force) } else { @($location) }
    $records = @(Read-FolderManifest)
    $touched = New-Object 'System.Collections.Generic.List[string]'
    $skipped = 0
    $failed = 0
    foreach ($folder in $targets) {
        # Bez sistemskih, skrivenih i povezanih fascikli, razvojnih kesova i Windows stabala.
        $protected = @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData, $env:LOCALAPPDATA, $env:APPDATA) |
            Where-Object { $_ -and ($folder.FullName -ieq $_ -or $folder.FullName.StartsWith($_.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) }
        if ($protected -or $folder.FullName -ieq (Join-Path $env:SystemDrive 'Users') -or ($folder.Attributes -band 0x406) -ne 0 -or $folder.Name.StartsWith('.')) { $skipped++; continue }
        try {
            $ini = Join-Path $folder.FullName 'desktop.ini'
            $record = $records | Where-Object { $_.DesktopIniPath -ieq $ini } | Select-Object -First 1
            # Poznate korisnicke fascikle imaju poseban simbol (Slike, Muzika...) i ostaju takve.
            if ($record -and $record.Kind -ne 'Ordinary') { $skipped++; continue }
            if (Test-Path -LiteralPath $ini) {
                if (([IO.File]::GetAttributes($ini) -band 0x400) -ne 0) { $skipped++; continue }
                $existing = Get-DesktopIniIcon $ini
                if ($existing -and $existing -notmatch '(?i)[\\/]StudentiPobedili[\\/]Icons[\\/]') { $skipped++; continue }
            }
            if (-not $record) {
                $existed = Test-Path -LiteralPath $ini -PathType Leaf
                $backup = ''
                $iniAttributes = $null
                if ($existed) {
                    $iniAttributes = [int][IO.File]::GetAttributes($ini)
                    $backup = New-BackupPath 'desktop' 'ini'
                    Copy-Item -LiteralPath $ini -Destination $backup -Force
                }
                $records += [pscustomobject]@{
                    Kind = 'Ordinary'; FolderPath = $folder.FullName; DesktopIniPath = $ini
                    Existed = $existed; BackupFile = $backup
                    FolderAttributes = [int][IO.File]::GetAttributes($folder.FullName)
                    DesktopIniAttributes = $iniAttributes
                }
                Save-FolderManifest $records
            }
            Set-DesktopIniIcon $ini ($icon + ',0')
            $attributes = [int][IO.File]::GetAttributes($folder.FullName)
            Set-FileAttributesSafe $folder.FullName ($attributes -bor 1)
            $touched.Add($folder.FullName)
        } catch {
            $failed++
            Write-Warning ('Nije promenjena {0}: {1}' -f $folder.FullName, $_.Exception.Message)
        }
    }
    if ($touched.Count -gt 0) {
        Send-ShellRefresh $touched.ToArray()
        Restart-ExplorerWithFreshThumbnails
    }
    Write-Host ('Postavljeno: {0}; preskoceno: {1}; neuspesno: {2}. Stil: {3}.' -f $touched.Count,$skipped,$failed,$Stil)
    Write-Host 'Opcija 9 ili deinstalacija vraca prethodne ikonice. Nove potfascikle obuhvatite ponovnim pokretanjem opcije F.'
    if ($failed -gt 0) { exit 1 }
    exit 0
} catch {
    Write-Host ('GRESKA: {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
