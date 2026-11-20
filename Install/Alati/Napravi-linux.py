"""Pravi Linux deo paketa (fascikla Linux/) iz istih mastera kao Windows verzija.

Pokretanje (Python 3 + Pillow):
    py -I Install/Alati/Napravi-linux.py

Pravi:
- Linux/icons/StudentiPobedili/  freedesktop tema ikonica (16-256 px, places/devices/apps)
- Linux/kde/*.colors             KDE Plasma seme boja (tamna Bordo i Svetla)
Pozadine se ne kopiraju u repo: install.sh ih uzima iz ../Wallpapers ili iz ./wallpapers u paketu.
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
spec = importlib.util.spec_from_file_location('napravi_ikonice', os.path.join(HERE, 'Napravi-ikonice.py'))
NI = importlib.util.module_from_spec(spec)
spec.loader.exec_module(NI)
from PIL import Image  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
LINUX = os.path.join(ROOT, 'Linux')
THEME = os.path.join(LINUX, 'icons', 'StudentiPobedili')
SIZES = [16, 22, 24, 32, 48, 64, 96, 128, 256]

# freedesktop ime ikonice -> (kontekst, master iz Icons/PNG)
ICONS = {
    'folder': ('places', 'Folder-3'),
    'folder-open': ('places', 'Folder-3'),
    # Dolphin obicne fascikle crta prema MIME tipu (inode/directory), ne kao "folder" (provereno uzivo)
    'inode-directory': ('mimetypes', 'Folder-3'),
    # KDE skracuje "folder-network" na "folder" u nasoj temi pre nego sto pita roditeljsku temu
    'folder-network': ('places', 'Network'),
    'folder-documents': ('places', 'Folder-Documents'),
    'folder-download': ('places', 'Folder-Downloads'),
    'folder-downloads': ('places', 'Folder-Downloads'),
    'folder-pictures': ('places', 'Folder-Pictures'),
    'folder-images': ('places', 'Folder-Pictures'),
    'folder-music': ('places', 'Folder-Music'),
    'folder-sound': ('places', 'Folder-Music'),
    'folder-videos': ('places', 'Folder-Video'),
    'folder-video': ('places', 'Folder-Video'),
    'folder-favorites': ('places', 'Folder-Favorites'),
    'folder-development': ('places', 'Folder-Projects'),
    'folder-projects': ('places', 'Folder-Projects'),
    'user-home': ('places', 'Home'),
    'folder-home': ('places', 'Home'),
    'user-desktop': ('places', 'Desktop'),
    'folder-desktop': ('places', 'Desktop'),
    'user-trash': ('places', 'RecycleBin-Empty'),
    'user-trash-full': ('places', 'RecycleBin-Full'),
    'trash-empty': ('places', 'RecycleBin-Empty'),
    'trash-full': ('places', 'RecycleBin-Full'),
    'network-workgroup': ('places', 'Network'),
    'folder-remote': ('places', 'Network'),
    'network-server': ('places', 'Network'),
    'computer': ('devices', 'ThisPC'),
    'drive-harddisk': ('devices', 'Drive'),
    'drive-harddisk-system': ('devices', 'Drive'),
    'drive-removable-media': ('devices', 'Drive'),
    'system-file-manager': ('apps', 'Explorer'),
    'org.gnome.Nautilus': ('apps', 'Explorer'),
    'org.kde.dolphin': ('apps', 'Explorer'),
    'nemo': ('apps', 'Explorer'),
    'thunar': ('apps', 'Explorer'),
    'preferences-system': ('apps', 'Settings'),
    'org.gnome.Settings': ('apps', 'Settings'),
    'systemsettings': ('apps', 'Settings'),
}


def build_icons():
    base = Image.open(os.path.join(HERE, 'izvor', 'Folder-bez-broja-512.png')).convert('RGBA')
    cache = {}
    dirs = []
    for size in SIZES:
        for ctx in ('apps', 'devices', 'mimetypes', 'places'):
            d = os.path.join(THEME, f'{size}x{size}', ctx)
            os.makedirs(d, exist_ok=True)
            dirs.append((f'{size}x{size}/{ctx}', size, ctx))
    for name, (ctx, master) in ICONS.items():
        for size in SIZES:
            key = (master, size)
            if key not in cache:
                cache[key] = NI.render(master, size, base)
            cache[key].save(os.path.join(THEME, f'{size}x{size}', ctx, name + '.png'), optimize=True)
    ctx_name = {'apps': 'Applications', 'devices': 'Devices', 'mimetypes': 'MimeTypes', 'places': 'Places'}
    lines = ['[Icon Theme]', 'Name=Studenti Pobedili', 'Comment=Bordo ikonice - Studenti pobedili (nezvanicna fan-made tema)',
             'Inherits=breeze,Adwaita,hicolor', 'Example=folder', '',
             'Directories=' + ','.join(d for d, _, _ in dirs), '']
    for d, size, ctx in dirs:
        lines += [f'[{d}]', f'Size={size}', f'Context={ctx_name[ctx]}', 'Type=Fixed', '']
    with open(os.path.join(THEME, 'index.theme'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines))
    print('ikonice:', len(ICONS), 'imena x', len(SIZES), 'velicina')


# ---------------------------------------------------------------- KDE seme boja
NEUTRAL = dict(negative='218,68,83', neutral='246,116,0', positive='39,174,96', visited='155,89,182')


def colorset(bg, bg_alt, fg, fg_inactive, accent, hover, link, active=None):
    return {
        'BackgroundAlternate': bg_alt, 'BackgroundNormal': bg,
        'DecorationFocus': accent, 'DecorationHover': hover,
        'ForegroundActive': active or hover, 'ForegroundInactive': fg_inactive, 'ForegroundLink': link,
        'ForegroundNegative': NEUTRAL['negative'], 'ForegroundNeutral': NEUTRAL['neutral'],
        'ForegroundNormal': fg, 'ForegroundPositive': NEUTRAL['positive'], 'ForegroundVisited': NEUTRAL['visited'],
    }


def scheme(dark):
    if dark:
        acc, hov, link = '152,31,52', '226,84,108', '255,138,160'
        fg, fgi = '247,238,240', '178,158,164'
        sets = {
            'Window': colorset('36,24,28', '46,32,37', fg, fgi, acc, hov, link),
            'View': colorset('26,17,20', '33,22,26', fg, fgi, acc, hov, link),
            'Button': colorset('50,34,40', '70,26,38', fg, fgi, acc, hov, link),
            'Header': colorset('58,14,30', '46,12,24', fg, fgi, acc, hov, link),
            'Header][Inactive': colorset('36,24,28', '46,32,37', fg, fgi, acc, hov, link),
            'Selection': colorset(acc, '110,22,40', '255,255,255', '235,205,212', acc, hov, '255,214,222', '255,255,255'),
            'Tooltip': colorset('26,17,20', '36,24,28', fg, fgi, acc, hov, link),
            'Complementary': colorset('20,12,15', '30,18,22', fg, fgi, acc, hov, link),
        }
        wm = {'activeBackground': '96,14,36', 'activeBlend': '255,255,255', 'activeForeground': '255,255,255',
              'inactiveBackground': '40,27,31', 'inactiveBlend': '178,158,164', 'inactiveForeground': '178,158,164'}
        name, cid = 'Studenti Pobedili Bordo', 'StudentiPobediliBordo'
    else:
        acc, hov, link = '152,31,52', '186,44,70', '152,31,52'
        fg, fgi = '33,22,26', '120,100,106'
        sets = {
            'Window': colorset('246,240,239', '237,229,229', fg, fgi, acc, hov, link),
            'View': colorset('255,252,251', '248,242,241', fg, fgi, acc, hov, link),
            'Button': colorset('241,232,232', '232,220,221', fg, fgi, acc, hov, link),
            'Header': colorset('239,229,229', '246,240,239', fg, fgi, acc, hov, link),
            'Header][Inactive': colorset('246,240,239', '237,229,229', fg, fgi, acc, hov, link),
            'Selection': colorset(acc, '200,120,136', '255,255,255', '248,220,226', acc, hov, '255,214,222', '255,255,255'),
            'Tooltip': colorset('255,252,251', '246,240,239', fg, fgi, acc, hov, link),
            'Complementary': colorset('36,24,28', '46,32,37', '247,238,240', '178,158,164', acc, '226,84,108', '255,138,160'),
        }
        wm = {'activeBackground': '152,31,52', 'activeBlend': '255,255,255', 'activeForeground': '255,255,255',
              'inactiveBackground': '237,229,229', 'inactiveBlend': '120,100,106', 'inactiveForeground': '120,100,106'}
        name, cid = 'Studenti Pobedili Svetla', 'StudentiPobediliSvetla'
    out = ['[ColorEffects:Disabled]', 'Color=56,56,56', 'ColorAmount=0', 'ColorEffect=0', 'ContrastAmount=0.65',
           'ContrastEffect=1', 'IntensityAmount=0.1', 'IntensityEffect=2', '',
           '[ColorEffects:Inactive]', 'ChangeSelectionColor=true', 'Color=112,111,110', 'ColorAmount=0.025',
           'ColorEffect=2', 'ContrastAmount=0.1', 'ContrastEffect=2', 'Enable=false', 'IntensityAmount=0', 'IntensityEffect=0', '']
    for set_name, values in sets.items():
        out.append(f'[Colors:{set_name}]')
        out += [f'{k}={v}' for k, v in values.items()]
        out.append('')
    out += ['[General]', f'ColorScheme={cid}', f'Name={name}', 'shadeSortColumn=true', '', '[KDE]', 'contrast=4', '', '[WM]']
    out += [f'{k}={v}' for k, v in wm.items()]
    os.makedirs(os.path.join(LINUX, 'kde'), exist_ok=True)
    with open(os.path.join(LINUX, 'kde', cid + '.colors'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out) + '\n')
    print('KDE sema:', cid)


def build_tarball():
    """dist/StudentiPobedili-Linux.tar.gz: install.sh (0755), uputstvo, ikonice, seme, pozadine."""
    import tarfile
    dist = os.path.join(ROOT, 'dist'); os.makedirs(dist, exist_ok=True)
    out = os.path.join(dist, 'StudentiPobedili-Linux.tar.gz')
    top = 'StudentiPobedili-Linux'

    def norm(ti, mode):
        ti.uid = ti.gid = 0; ti.uname = ti.gname = 'root'; ti.mode = mode
        return ti
    with tarfile.open(out, 'w:gz', compresslevel=9) as tar:
        tar.add(os.path.join(LINUX, 'install.sh'), f'{top}/install.sh', filter=lambda t: norm(t, 0o755))
        tar.add(os.path.join(LINUX, 'PROCITAJ-ME.txt'), f'{top}/PROCITAJ-ME.txt', filter=lambda t: norm(t, 0o644))
        for sub in ('icons', 'kde'):
            tar.add(os.path.join(LINUX, sub), f'{top}/{sub}', filter=lambda t: norm(t, 0o755 if t.isdir() else 0o644))
        walls = os.path.join(ROOT, 'Wallpapers')
        for f in sorted(os.listdir(walls)):
            tar.add(os.path.join(walls, f), f'{top}/wallpapers/{f}', filter=lambda t: norm(t, 0o644))
    print('paket:', out, round(os.path.getsize(out) / 1048576, 1), 'MB')


if __name__ == '__main__':
    build_icons()
    scheme(dark=True)
    scheme(dark=False)
    if '--paket' in sys.argv:
        build_tarball()
