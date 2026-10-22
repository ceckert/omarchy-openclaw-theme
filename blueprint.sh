#!/bin/bash
# Blueprint lobster intro: a coral scan line prints the lobster over a dim
# ghost of itself, then a sonar ping settles onto the still.
set -euo pipefail
cd "$(dirname "$0")"
W=2560 H=1440 N=180 FPS=30
out=bp-png
rm -rf "$out" && mkdir -p "$out"

magick bp-up.png -resize ${W}x${H}! bp-full.png
magick bp-full.png -modulate 40 bp-dim.png
# mask strip: white, 120px ramp, black; cropped at an offset per frame
magick -size ${W}x${H} xc:white \( -size ${W}x120 gradient:white-black \) -size ${W}x${H} xc:black -append bp-ramp.png
# coral scan glow: a hot core line inside a soft halo
magick -size ${W}x240 xc:none -fill 'rgba(255,77,77,0.10)' -draw "rectangle 0,40 $W,200" \
  -fill 'rgba(255,109,90,0.28)' -draw "rectangle 0,100 $W,140" -blur 0x30 \
  -fill 'rgba(255,214,200,0.95)' -draw "rectangle 0,118 $W,122" bp-glow.png

python3 - "$W" "$H" "$N" "$FPS" > bp-cmds.txt <<'EOF'
import sys, math
W, H, N, FPS = map(int, sys.argv[1:])
def clamp(x): return max(0.0, min(1.0, x))
def smooth(a, b, t):
    u = clamp((t - a) / (b - a)); return u * u * (3 - 2 * u)
for i in range(N):
    t = i / FPS
    s = smooth(0.5, 4.0, t)
    y = int(-160 + s * (H + 320))            # scan line position
    off = max(0, min(H + 120, H + 60 - y))   # crop offset into the ramp strip
    glow = smooth(0.4, 0.8, t) * (1 - smooth(3.6, 4.1, t))
    u = clamp((t - 4.0) / 1.5)
    ring = ""
    if 0 < u < 1:
        r = 120 + 1100 * (1 - (1 - u) ** 2)
        a = 0.55 * (1 - u) ** 1.5
        ring = (f' -fill none -stroke "rgba(255,90,74,{a:.3f})" -strokewidth {6 + 10 * (1 - u):.1f}'
                f' -draw "circle 1280,700 {1280 + r:.0f},700"'
                f' -stroke "rgba(0,229,204,{a * 0.6:.3f})" -strokewidth 3 -draw "circle 1280,700 {1280 + r * 0.82:.0f},700"')
    cmd = (f'magick bp-dim.png bp-full.png \\( bp-ramp.png -crop {W}x{H}+0+{off} +repage \\) -composite')
    if glow > 0.001:
        cmd += f' \\( bp-glow.png -channel A -evaluate multiply {glow:.3f} +channel \\) -geometry +0+{y - 120} -compose screen -composite -compose over'
    cmd += f'{ring} bp-png/f{i:04d}.png'
    print(cmd)
EOF
xargs -P6 -d '\n' -I{} sh -c '{}' < bp-cmds.txt
ls "$out" | wc -l
