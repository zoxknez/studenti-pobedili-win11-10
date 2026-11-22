"""Real-ESRGAN x4plus uvecanje (CPU, u plocicama).

Potrebno: pip install spandrel torch, i model RealESRGAN_x4plus.pth
(https://github.com/xinntao/Real-ESRGAN/releases/tag/v0.1.0).

Pokretanje: python Install/Alati/Uvecaj-pozadine.py RealESRGAN_x4plus.pth Install/Alati/izvor/pozadine IZLAZ
Posle toga: python Install/Alati/Napravi-pozadine.py IZLAZ
"""
import glob
import os
import sys
import time

import numpy as np
import torch
from PIL import Image
from spandrel import ModelLoader

model_path, src, dst = sys.argv[1:4]
os.makedirs(dst, exist_ok=True)
torch.set_num_threads(os.cpu_count() or 4)
model = ModelLoader().load_from_file(model_path).eval()
SCALE = model.scale
TILE, PAD = 320, 16


@torch.inference_mode()
def upscale(img):
    a = torch.from_numpy(np.asarray(img, dtype=np.float32) / 255.0).permute(2, 0, 1)[None]
    _, _, h, w = a.shape
    out = torch.zeros((1, 3, h * SCALE, w * SCALE))
    for y in range(0, h, TILE):
        for x in range(0, w, TILE):
            y0, x0 = max(y - PAD, 0), max(x - PAD, 0)
            y1, x1 = min(y + TILE + PAD, h), min(x + TILE + PAD, w)
            r = model(a[:, :, y0:y1, x0:x1])
            ty, tx = (y - y0) * SCALE, (x - x0) * SCALE
            th, tw = (min(y + TILE, h) - y) * SCALE, (min(x + TILE, w) - x) * SCALE
            out[:, :, y * SCALE:y * SCALE + th, x * SCALE:x * SCALE + tw] = r[:, :, ty:ty + th, tx:tx + tw]
    o = (out[0].clamp(0, 1).permute(1, 2, 0).numpy() * 255.0).round().astype(np.uint8)
    return Image.fromarray(o)


for f in sorted(glob.glob(os.path.join(src, '*.png'))):
    name = os.path.basename(f)
    target = os.path.join(dst, name)
    if os.path.exists(target):
        continue
    t = time.time()
    up = upscale(Image.open(f).convert('RGB'))
    up.save(target + '.tmp.png', compress_level=1)
    os.replace(target + '.tmp.png', target)
    print(f'{name} {up.size} {time.time() - t:.0f}s', flush=True)
print('GOTOVO', flush=True)
