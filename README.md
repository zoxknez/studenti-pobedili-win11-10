<div align="center">

<img src="web/assets/favicon.svg" width="72" alt="">

# Studenti pobedili — tema za Windows 11 i 10

**Bordo tema sa 8 pozadina u 4K, 31 ikonicom, zaključanim ekranom i zvukom.**
Instalacija jednim klikom, bez admin prava, potpuna deinstalacija.

[**⬇ Preuzmite paket (ZIP)**](https://github.com/zoxknez/studenti-pobedili-win11-10/releases/latest/download/StudentiPobedili-Windows-v2.zip)
&nbsp;·&nbsp; [Sva izdanja](https://github.com/zoxknez/studenti-pobedili-win11-10/releases)

<img src="web/assets/hero.webp" width="860" alt="Windows radna površina sa temom Studenti pobedili">

</div>

## Instalacija

1. Preuzmite ZIP i raspakujte ga (desni klik › **Extract All**).
2. Pokrenite **`INSTALIRAJ.cmd`**. Ako Windows prikaže upozorenje: *More info › Run anyway*.
3. Izaberite **[1] KOMPLETNO – Bordo** (ili [2] za svetlu varijantu).

Samo tema, bez skripti: preuzmite
[`Studenti-Pobedili-Bordo.deskthemepack`](https://github.com/zoxknez/studenti-pobedili-win11-10/releases/latest/download/Studenti-Pobedili-Bordo.deskthemepack)
ili
[`Studenti-Pobedili-Svetla.deskthemepack`](https://github.com/zoxknez/studenti-pobedili-win11-10/releases/latest/download/Studenti-Pobedili-Svetla.deskthemepack)
i otvorite ga dvoklikom (pre toga zatvorite Settings).

## Šta dobijate

| | |
|---|---|
| **Tema** | Bordo akcenat `#981F34` (kontrast 8,1:1), tamni ili svetli režim, bordo traka zadataka i naslovne trake |
| **Pozadine** | 8 pozadina 3840×2160 i slideshow koji ne stavlja tekst ispod desktop ikonica |
| **Ikonice** | 31 ikonica (16–256 px, uključujući 20 i 40 px za 125% i 250%), leva navigacija Explorer-a sa posebnom siluetom za svaku stavku, File Explorer na traci zadataka |
| **Zaključani ekran** | Postavlja se automatski (16:9), plus dve uspravne verzije za telefon |
| **Zvuk** | Kratak zvuk „Pobeda“ za obaveštenja, uključuje se i isključuje jednom opcijom |
| **Vraćanje** | Opcija **D** vraća prethodnu temu, boje, ikonice i zvuk i briše fajlove paketa |

<div align="center"><img src="Preview/Pregled-Ikonica.png" width="860" alt="Pregled ikonica"></div>

## Bezbednost

- Menja samo podešavanja **trenutnog korisnika** (HKCU), bez programa i interneta.
- Pre svake izmene čuva original (`%LOCALAPPDATA%\StudentiPobedili`).
- Izuzetak je opciona crvena „3“ za *sve* obične fascikle: Windows tu ikonicu čita samo iz HKLM, pa traži UAC potvrdu.

## Struktura

```
INSTALIRAJ.cmd          glavni meni
Install/                PowerShell skripte (tema, ikonice, zaključani ekran, zvuk, deinstalacija)
Install/Alati/          alati: Napravi-themepack.ps1, Napravi-ikonice.py (Python + Pillow)
Teme/                   .deskthemepack paketi
Wallpapers/ LockScreen/ Icons/ Sounds/ Preview/
web/                    sajt (Vercel: vercel.json → outputDirectory "web")
```

---

<sub>Nezvanična fan-made personalizacija. Nije zvanični Windows paket niti zvanični proizvod Studentske liste. Windows je zaštitni znak kompanije Microsoft.</sub>
