# Postavlja sliku zakljucanog ekrana za trenutnog korisnika preko Windows API-ja (bez admin prava).
param([string]$Slika = '03-Zakljucani-ekran-PC-3840x2160.jpg')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Zajednicko.ps1')

try {
    Assert-Package
    New-Item -ItemType Directory -Path $LockDir -Force | Out-Null
    Copy-Item -Path (Join-Path $Package 'LockScreen\*') -Destination $LockDir -Force
    $image = Join-Path $LockDir $Slika
    if (-not (Test-Path -LiteralPath $image)) { throw "Nedostaje slika: $image" }

    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $methods = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
    $asTaskOp  = $methods | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
    $asTaskAct = $methods | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1
    [void][Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
    [void][Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]

    $opFile = [Windows.Storage.StorageFile]::GetFileFromPathAsync($image)
    $taskFile = $asTaskOp.MakeGenericMethod([Windows.Storage.StorageFile]).Invoke($null, @($opFile))
    if (-not $taskFile.Wait(15000)) { throw 'Isteklo vreme za otvaranje slike.' }
    $taskSet = $asTaskAct.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($taskFile.Result)))
    if (-not $taskSet.Wait(15000)) { throw 'Isteklo vreme za postavljanje zakljucanog ekrana.' }
    if ($taskSet.Exception) { throw $taskSet.Exception.InnerException }

    Write-Host 'Zakljucani ekran je postavljen. Proverite sa Win + L.' -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("GRESKA: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Rucno: Settings > Personalization > Lock screen > Picture > Browse photos,'
    Write-Host ("pa izaberite sliku iz: {0}" -f $LockDir)
    exit 1
}
