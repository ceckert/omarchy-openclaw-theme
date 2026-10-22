# OpenClaw theme art source

The generators behind the theme's wallpapers, intro videos and boot logo. This branch holds no theme files of its own; `main` is the theme.

- `molty.py`: the Molty scene, written as one SVG per frame. Molty's shapes and idle motions come from OpenClaw's `apps/linux/ui/mascot.svg`.
- `blueprint.sh`: the scan-line and sonar-ping intro over the upscaled Crabbox lobster.
- `build.sh`: runs both, composes the boot and unlock logo from the two projects' logos, stacks the screensaver art, and writes the results into a theme checkout.

## Rebuild

Needs an OpenClaw checkout, an Omarchy checkout (for the Omarchy logo), Omarchy itself (for `omarchy-transcode-ascii`), `python3`, `rsvg-convert` (librsvg), ImageMagick 7 and `ffmpeg` with libx264.

```bash
git worktree add ../theme main
./build.sh ~/src/openclaw ~/src/omarchy ../theme
```

Intros are 2560x1440 at 30 fps and six seconds long, and each one ends on the frame its still is rendered from, so the handoff from video to wallpaper is seamless. Keep that true when you retime an intro: the still is always rendered from the intro's last frame.

The preview images are screenshots, not generated: `preview.png` is the desktop with the theme applied, and `preview-unlock.png` comes from `omarchy plymouth preview '#111122' '#e2dfef' unlock.png preview-unlock.png`.
