# Ukljucuje / iskljucuje zvuk "Pobeda" za Windows obavestenja (trenutni korisnik).
param([switch]$Vrati)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Zajednicko.ps1')

$eventKey   = 'HKCU:\AppEvents\Schemes\Apps\.Default\Notification.Default\.Current'
$soundFile  = Join-Path $SoundsDir 'Pobeda-Potvrda.wav'
$backupFile = Join-Path $BackupDir 'zvuk-obavestenja.json'

try {
    $current = $null
    if (Test-Path -LiteralPath $eventKey) { $current = (Get-ItemProperty -LiteralPath $eventKey).'(default)' }
    $isOurs = [bool]($current -and $current -match 'StudentiPobedili')

    if ($Vrati -or $isOurs) {
        if (-not $isOurs) { Write-Host 'Zvuk paketa nije ukljucen - nema sta da se vrati.'; exit 0 }
        $original = '%SystemRoot%\media\Windows Notify System Generic.wav'
        if (Test-Path -LiteralPath $backupFile) {
            $saved = (Get-Content -LiteralPath $backupFile -Raw | ConvertFrom-Json).Value
            if ($null -ne $saved) { $original = [string]$saved }
        }
        New-Item -Path $eventKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $eventKey -Name '(default)' -Value $original
        Remove-Item -LiteralPath $backupFile -Force -ErrorAction SilentlyContinue
        Write-Host 'Vracen je originalni zvuk obavestenja.' -ForegroundColor Green
        exit 0
    }

    Assert-Package
    New-Item -ItemType Directory -Path $SoundsDir, $BackupDir -Force | Out-Null
    Copy-Item -Path (Join-Path $Package 'Sounds\*') -Destination $SoundsDir -Force
    if (-not (Test-Path -LiteralPath $backupFile)) {
        [pscustomobject]@{ Value = $current } | ConvertTo-Json | Set-Content -LiteralPath $backupFile -Encoding UTF8
    }
    New-Item -Path $eventKey -Force | Out-Null
    Set-ItemProperty -LiteralPath $eventKey -Name '(default)' -Value $soundFile
    (New-Object System.Media.SoundPlayer $soundFile).PlaySync()
    Write-Host 'Zvuk "Pobeda" je postavljen za Windows obavestenja. Ponovnim izborom opcije se iskljucuje.' -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("GRESKA: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
