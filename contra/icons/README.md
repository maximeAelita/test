# CONTRA — app icon

The icon is generated from a single self-contained source, `icon.html`, which draws
the mark (jungle horizon and palms, an inset red frame, a heavy ember-gradient "C"
with a muzzle spark, CRT scanlines) on a canvas at any size via `?s=NNN`.

Everything is drawn as canvas paths — no webfonts — so it rasterises identically in a
bare container.

## Regenerate the PNGs

```bash
npm i -D playwright     # or reuse an existing Playwright install
node make-icons.js      # writes icon-<size>.png for every size below
```

Set `CHROME=/path/to/chrome` if Playwright's bundled Chromium isn't on the default path.

## Sizes produced

| File | Use |
| --- | --- |
| `icon-1024.png` | iOS App Store icon · master source |
| `icon-512.png` | web manifest icon (`manifest.json`) |
| `icon-256.png`, `icon-64.png`, `icon-32.png` | favicon / desktop layers |
| `icon-192.png` | web manifest icon · Android home screen |
| `icon-180.png`, `icon-167.png`, `icon-152.png`, `icon-120.png`, `icon-76.png` | iOS home-screen (iPhone/iPad @2x/@3x) |

The PNGs are full-bleed squares so iOS can apply its own corner mask; the red frame is
inset to stay clear of that rounding. Tweak colors/layout in `icon.html` and re-run.
