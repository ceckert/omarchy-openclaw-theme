#!/usr/bin/env python3
"""Molty wallpaper + intro frames. Molty geometry comes from OpenClaw's
apps/linux/ui/mascot.svg (MIT, OpenClaw Foundation); the idle motions mirror
its float / wiggle / blink / snap keyframes."""
import math, random, sys, os

W, H = 3840, 2160
DUR, FPS = 6.0, 30
NAVY, DEEP = "#1b1a3a", "#080811"
CORAL, CORAL_D, TEAL = "#ff4d4d", "#991b1b", "#00e5cc"

def clamp(x, a=0.0, b=1.0): return max(a, min(b, x))
def smooth(a, b, t):
    u = clamp((t - a) / (b - a)); return u * u * (3 - 2 * u)
def ease_out_back(u, k=1.9):
    u = clamp(u) - 1; return 1 + (k + 1) * u ** 3 + k * u ** 2
def pulse(a, b, t):
    """0 -> 1 -> 0 between a and b, smooth."""
    if t <= a or t >= b: return 0.0
    return math.sin(math.pi * (t - a) / (b - a)) ** 2

rng = random.Random(7)
BUBBLES = [dict(x=rng.uniform(0, W), y0=rng.uniform(0, H + 400), r=rng.uniform(6, 26),
                v=rng.uniform(40, 130), ph=rng.uniform(0, 6.28), sway=rng.uniform(10, 40))
           for _ in range(34)]
DOTS = [(x, y) for x in range(60, W, 120) for y in range(60, H, 120)]

def bubbles(t):
    out = []
    for b in BUBBLES:
        y = (b["y0"] - b["v"] * (t + 20)) % (H + 400) - 200
        x = b["x"] + b["sway"] * math.sin(b["ph"] + t * 0.9 + y / 300)
        r = b["r"]
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="#00e5cc" fill-opacity="0.04" '
                   f'stroke="#bff8f0" stroke-opacity="0.22" stroke-width="{max(2, r / 7):.1f}"/>'
                   f'<circle cx="{x - r * .35:.1f}" cy="{y - r * .35:.1f}" r="{r * .22:.1f}" fill="#ffffff" fill-opacity="0.35"/>')
    return "".join(out)

def molty(t):
    # entrance: rise from below, overshoot, land
    rise = ease_out_back((t - 0.15) / 1.05)
    y_off = (1 - rise) * 1500
    tilt = 7 * math.sin(t * 9) * (1 - smooth(0.2, 1.3, t))
    # landing squash, pivot at the feet
    sq = pulse(1.05, 1.55, t) * 0.11 - pulse(1.5, 1.85, t) * 0.04
    sx, sy = 1 + sq * 0.8, 1 - sq
    # idle float (one 4s cycle), back to rest for the final still
    fl = -5 * (1 - math.cos(2 * math.pi * clamp((t - 1.6) / 4.0))) / 2
    # claws: a happy double snap, right one 0.12s behind the left
    def snap(d): return -16 * (pulse(2.25 + d, 2.65 + d, t) + pulse(2.75 + d, 3.15 + d, t))
    lc, rc = snap(0), -snap(0.12)
    # antennae: wiggle that calms down to rest
    amp = 3 + 6 * (1 - smooth(0.0, 1.6, t))
    wig = amp * math.sin(t * math.pi) * (1 - smooth(4.6, 5.9, t))
    # blinks
    blink = max(pulse(1.85, 2.05, t), pulse(4.05, 4.22, t), pulse(4.3, 4.47, t))
    ey = 1 - 0.9 * blink
    s = 7.2
    cx, cy = W / 2, H / 2 + 40
    grad = ('<linearGradient id="lg" x1="0%" y1="0%" x2="100%" y2="100%">'
            f'<stop offset="0%" stop-color="{CORAL}"/><stop offset="100%" stop-color="{CORAL_D}"/></linearGradient>')
    eye = lambda x: (f'<g transform="translate({x} 35) scale(1 {ey:.3f}) translate({-x} -35)">'
                     f'<circle cx="{x}" cy="35" r="6" fill="#050810"/>'
                     f'<circle cx="{x + 1}" cy="34" r="2.5" fill="{TEAL}"/></g>')
    body = (f'<g transform="translate({cx:.1f} {cy + y_off:.1f}) rotate({tilt:.2f}) scale({s}) translate(-60 -60)">'
            f'<g transform="translate(0 {fl:.2f}) translate(60 110) scale({sx:.3f} {sy:.3f}) translate(-60 -110)">'
            '<path d="M60 10 C30 10 15 35 15 55 C15 75 30 95 45 100 L45 110 L55 110 L55 100 C55 100 60 102 65 100 L65 110 L75 110 L75 100 C90 95 105 75 105 55 C105 35 90 10 60 10Z" fill="url(#lg)"/>'
            f'<path transform="rotate({lc:.2f} 26 53)" d="M20 45 C5 40 0 50 5 60 C10 70 20 65 25 55 C28 48 25 45 20 45Z" fill="url(#lg)"/>'
            f'<path transform="rotate({rc:.2f} 94 53)" d="M100 45 C115 40 120 50 115 60 C110 70 100 65 95 55 C92 48 95 45 100 45Z" fill="url(#lg)"/>'
            f'<path transform="rotate({wig:.2f} 37.5 11)" d="M45 15 Q35 5 30 8" stroke="{CORAL}" stroke-width="3" stroke-linecap="round" fill="none"/>'
            f'<path transform="rotate({-wig:.2f} 82.5 11)" d="M75 15 Q85 5 90 8" stroke="{CORAL}" stroke-width="3" stroke-linecap="round" fill="none"/>'
            + eye(45) + eye(75) + '</g></g>')
    # floor shadow follows the height above the ground
    lift = clamp(1 - (y_off / 1500)) * (1 + fl / 40)
    shadow = (f'<ellipse cx="{cx}" cy="{cy + 50 * s + 6}" rx="{40 * s * lift:.1f}" ry="{6 * s * lift:.1f}" '
              f'fill="#000" fill-opacity="{0.35 * lift:.3f}"/>')
    glow_o = 0.55 * smooth(0.5, 1.6, t)
    glow = f'<circle cx="{cx}" cy="{cy - 40}" r="900" fill="url(#glow)" opacity="{glow_o:.3f}"/>'
    return grad, glow + shadow + body

def heart(t):
    u = clamp((t - 3.25) / 2.1)
    if u <= 0 or u >= 1: return ""
    o = math.sin(math.pi * u) ** 1.5
    x, y = W / 2 + 470 + 60 * math.sin(u * 7), H / 2 - 420 - 520 * u
    k = 6.5 + 2.0 * u
    return (f'<path transform="translate({x:.1f} {y:.1f}) scale({k:.2f}) translate(-12 -11)" '
            'd="M12 21s-7.5-4.6-10-9.3C.4 8.6 2.3 4.5 6.2 4.5c2.4 0 4.1 1.4 5.8 3.4 1.7-2 3.4-3.4 5.8-3.4 3.9 0 5.8 4.1 4.2 7.2C19.5 16.4 12 21 12 21z" '
            f'fill="{TEAL}" fill-opacity="{0.9 * o:.3f}"/>')

def frame(t):
    grad, mol = molty(t)
    rays = "".join(
        f'<polygon points="{x0},-20 {x0 + w},-20 {x0 + w + 900},{H} {x0 + 500},{H}" fill="#9fe9ff" '
        f'opacity="{0.035 + 0.015 * math.sin(t * 1.3 + i):.4f}"/>'
        for i, (x0, w) in enumerate([(700, 260), (1500, 140), (2350, 320), (3100, 180)]))
    dots = "".join(f'<circle cx="{x}" cy="{y}" r="2.6"/>' for x, y in DOTS)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}"><defs>'
            f'<radialGradient id="bg" cx="50%" cy="45%" r="75%"><stop offset="0%" stop-color="{NAVY}"/><stop offset="100%" stop-color="{DEEP}"/></radialGradient>'
            '<radialGradient id="glow"><stop offset="0%" stop-color="#ff4d4d" stop-opacity="0.55"/><stop offset="45%" stop-color="#ff4d4d" stop-opacity="0.12"/><stop offset="100%" stop-color="#ff4d4d" stop-opacity="0"/></radialGradient>'
            '<linearGradient id="fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#080811" stop-opacity="0"/><stop offset="1" stop-color="#080811" stop-opacity="0.7"/></linearGradient>'
            f'{grad}</defs><rect width="{W}" height="{H}" fill="url(#bg)"/>{rays}'
            f'<g fill="#8f8cc0" fill-opacity="0.10">{dots}</g>'
            f'<rect y="{H * 0.6}" width="{W}" height="{H * 0.4}" fill="url(#fade)"/>'
            f'{bubbles(t)}{mol}{heart(t)}</svg>')

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    n = int(DUR * FPS)
    for i in range(n):
        open(f"{out}/f{i:04d}.svg", "w").write(frame(i / FPS))
    open(f"{out}/still.svg", "w").write(frame((n - 1) / FPS))
