#!/bin/bash
# Regenerate the theme's backgrounds, intros, boot logo and screensaver from OpenClaw and
# Omarchy checkouts. Needs python3, rsvg-convert, ImageMagick 7 and ffmpeg (libx264).
#
#   ./build.sh <openclaw-checkout> <omarchy-checkout> <theme-dir>
set -euo pipefail

if (( $# != 3 )); then
  echo "Usage: $0 <openclaw-checkout> <omarchy-checkout> <theme-dir>" >&2
  exit 1
fi

src=$(realpath "$1")
omarchy=$(realpath "$2")
theme=$(realpath "$3")
here=$(dirname "$(realpath "$0")")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cp "$here"/molty.py "$here"/blueprint.sh "$work"/
cd "$work"
mkdir -p "$theme/backgrounds/intros"

render() { # <svg-dir> <png-dir>
  mkdir -p "$2"
  ls "$1"/f*.svg | xargs -P"$(nproc)" -I{} sh -c 'rsvg-convert -w 2560 -h 1440 "$1" -o "$2/$(basename "$1" .svg).png"' _ {} "$2"
}

encode() { # <png-dir> <out.mp4> [extra x264 args]
  ffmpeg -loglevel error -y -framerate 30 -i "$1/f%04d.png" -c:v libx264 -preset slow -crf 20 "${@:3}" \
    -pix_fmt yuv420p -movflags +faststart -an "$2"
}

# 1. Molty
python3 molty.py molty
render molty molty-png
encode molty-png "$theme/backgrounds/intros/1-molty.mp4" -tune animation
rsvg-convert -w 3840 -h 2160 molty/still.svg -o molty-still.png
magick molty-still.png -quality 92 "$theme/backgrounds/1-molty.webp"

# 2. Blueprint lobster: the source is a 16-colour 1024x576 PNG, so smooth its
# bands before upscaling, then tint it navy-to-cream with a little grain.
magick "$src/extensions/crabbox/assets/openclaw-worker-wallpaper.png" -colorspace sRGB -type TrueColor -depth 16 \
  -selective-blur 0x2.2+12% -filter LanczosSharp -resize 3840x2160! -unsharp 0x2+0.6+0.03 -gamma 0.9 -level 0%,92% \
  \( -size 1x256 gradient:'#0b0b1a-#fff3ec' \) -clut \
  \( -seed 7 -size 3840x2160 xc:gray50 +noise Gaussian -evaluate multiply 0.5 -evaluate add 25% \) \
  -compose overlay -define compose:args=8 -composite -depth 8 bp-up.png
bash blueprint.sh >/dev/null
encode bp-png "$theme/backgrounds/intros/2-blueprint-lobster.mp4"
magick bp-up.png -quality 90 "$theme/backgrounds/2-blueprint-lobster.webp"

# Boot and unlock logo: Omarchy's mark and wordmark x Molty and the OpenClaw
# wordmark. The mark is the Omarchy glyph (U+E900) from Omarchy's icon font and
# the wordmark is its logo.svg, both rendered in Omarchy green at final size.
magick -background none -fill '#a8cd76' -font "$omarchy/default/fonts/omarchy/omarchy.ttf" -pointsize 160 \
  label:$'\ue900' -trim +repage -resize x110 oma-icon.png
sed 's/#000/#a8cd76/g' "$omarchy/logo.svg" > oma-word.svg
rsvg-convert -h 66 oma-word.svg -o oma-word.png
magick oma-icon.png -background none \( -size 34x1 xc:none \) oma-word.png -gravity center +append oma-lockup.png
magick -size 90x90 xc:none -stroke '#00e5cc' -strokewidth 11 -draw 'line 20,20 70,70' -draw 'line 20,70 70,20' x.png
magick "$src/docs/assets/openclaw-hero-dark.png" -trim +repage -resize x176 oc-lockup.png
magick oma-lockup.png -background none \( -size 64x1 xc:none \) x.png \( -size 56x1 xc:none \) oc-lockup.png \
  -gravity center +append -trim +repage -resize 960x -strip "$theme/unlock.png"

# Screensaver: OMARCHY in Omarchy's own FIGlet wordmark (logo.txt), a plain x,
# and OpenClaw's wordmark converted to block characters, stacked and centred.
magick "$src/docs/assets/openclaw-hero-dark.png" -crop 760x423+430+0 +repage -trim +repage \
  -alpha extract -negate -bordercolor white -border 8 oc-mask.png
omarchy-transcode-ascii oc-mask.png oc-block.txt --width 92 --mode block >/dev/null
printf '%s\n' '▀█▄     ▄█▀' '  ▀█▄ ▄█▀' '    ███' '  ▄█▀ ▀█▄' '▄█▀     ▀█▄' > x.txt
python3 - "$omarchy/logo.txt" x.txt oc-block.txt > "$theme/screensaver.txt" <<'EOF'
import sys
blocks = []
for p in sys.argv[1:]:
    lines = [l.rstrip() for l in open(p, encoding="utf-8").read().rstrip("\n").split("\n")]
    while lines and not lines[-1].strip(): lines.pop()
    while lines and not lines[0].strip(): lines.pop(0)
    blocks.append(lines)
width = max(len(l) for b in blocks for l in b)
out = []
for i, b in enumerate(blocks):
    pad = (width - max(len(l) for l in b)) // 2
    out += [(" " * pad + l).rstrip() for l in b]
    if i < len(blocks) - 1: out.append("")
print("\n".join(out))
EOF

echo "Rebuilt assets in $theme"
