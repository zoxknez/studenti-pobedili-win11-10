# Pomocni alat za zakacene stavke leve navigacije (Quick access / Home). Pokrece se kao zaseban proces.
#   -Lista            ispisuje putanje zakacenih stavki, redom
#   -Prekidac <path>  menja stanje kacenja te fascikle
# Provereno uzivo (Windows 11 26220):
#  - lista se mora citati iz novog procesa (Shell kesira listu u okviru procesa);
#  - "unpinfromhome" nad fasciklom ne radi nista, a "pintohome" radi kao prekidac;
#  - glagol je asinhron, pa proces mora da obradjuje poruke nekoliko sekundi posle poziva.
param([switch]$Lista, [string]$Prekidac)
$ErrorActionPreference = 'Stop'
$shell = New-Object -ComObject Shell.Application
if ($Lista) {
    $qa = $shell.Namespace('shell:::{3936E9E4-D92C-4EEE-A85A-BC16D5EA0819}')
    if ($qa) { $qa.Items() | Where-Object { $_.ExtendedProperty('System.Home.IsPinned') -eq $true } | ForEach-Object { [string]$_.Path } }
    exit 0
}
if ($Prekidac) {
    Add-Type -AssemblyName System.Windows.Forms
    $item = $shell.Namespace((Split-Path -Parent $Prekidac)).ParseName((Split-Path -Leaf $Prekidac))
    if (-not $item) { exit 1 }
    $item.InvokeVerb('pintohome')
    $end = (Get-Date).AddSeconds(3)
    while ((Get-Date) -lt $end) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }
    exit 0
}
