@echo off
setlocal
cd /d "%~dp0"
title Studenti pobedili - tema za Windows 10 / 11

if not exist "%~dp0Install\Zajednicko.ps1" (
  echo.
  echo  Paket nije kompletan. Raspakujte CEO ZIP u novu fasciklu
  echo  ^(desni klik ^> Extract All^) i pokrenite INSTALIRAJ.cmd odatle.
  echo.
  pause
  exit /b 1
)

:menu
cls
echo.
echo   =========================================================
echo     STUDENTI POBEDILI  ^|  tema za Windows 10 / 11
echo   =========================================================
echo.
echo     [1]  KOMPLETNO - Bordo   (tamna tema, sve ikonice, zakljucani ekran)
echo     [2]  KOMPLETNO - Svetla  (svetla tema, sve ikonice, zakljucani ekran)
echo.
echo     [3]  Samo tema Bordo  (tamna)
echo     [4]  Samo tema Svetla
echo     [5]  Ikonice: Dokumenti, Preuzimanja..., Ovaj racunar, korpa, diskovi
echo     [6]  Ikonice: crvena "3" za SVE ostale fascikle  *
echo     [7]  Zakljucani ekran
echo     [8]  Zvuk obavestenja "Pobeda"  (ukljuci / iskljuci)
echo.
echo     [9]  Vrati originalne Windows ikonice
echo     [D]  Deinstaliraj sve i vrati prethodnu temu
echo     [0]  Izlaz
echo.
echo   Promene vaze za trenutnog korisnika, bez admin prava.
echo   * Windows ovu ikonicu cuva sistemski: trazi admin potvrdu (UAC),
echo     vazi za sve korisnike i kratko restartuje File Explorer.
echo.
choice /c 123456789D0 /n /m "  Izaberite opciju: "
set "opt=%errorlevel%"
echo.
if "%opt%"=="11" exit /b 0
if "%opt%"=="1" call :run Instaliraj.ps1 -Stil Bordo && call :run Postavi-ikonice.ps1 && call :run Zakljucani-ekran.ps1 && call :run Ikonica-svih-fascikli.ps1
if "%opt%"=="2" call :run Instaliraj.ps1 -Stil Svetla && call :run Postavi-ikonice.ps1 && call :run Zakljucani-ekran.ps1 && call :run Ikonica-svih-fascikli.ps1
if "%opt%"=="3" call :run Instaliraj.ps1 -Stil Bordo
if "%opt%"=="4" call :run Instaliraj.ps1 -Stil Svetla
if "%opt%"=="5" call :run Postavi-ikonice.ps1
if "%opt%"=="6" call :run Ikonica-svih-fascikli.ps1
if "%opt%"=="7" call :run Zakljucani-ekran.ps1
if "%opt%"=="8" call :run Zvuk.ps1
if "%opt%"=="9" call :run Vrati-ikonice.ps1 & call :run Ikonica-svih-fascikli.ps1 -Vrati
if "%opt%"=="10" call :run Deinstaliraj.ps1
echo.
echo   Pritisnite bilo koji taster za povratak u meni...
pause >nul
goto menu

:run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install\%~1" %2 %3
exit /b %errorlevel%
