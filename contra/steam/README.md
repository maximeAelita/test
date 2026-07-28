# IRONVINE — desktop / Steam build

The game is one self-contained HTML file. This folder wraps it in Electron so it
can ship as a Windows executable.

```bash
npm install
npm start          # runs copy-game.js, then launches it
npm run dist       # unpacked build into dist/
```

`copy-game.js` pulls `../index.html`, `../manifest.json` and `../icons/*.png` into
`game/`. That folder and `dist/` are build products and are gitignored — the parent
folder stays the single source of truth, so never edit `game/` directly.

## What the shell does

Deliberately very little: a borderless fullscreen window, no menu bar, no Node
integration in the page, and `backgroundThrottling` off so the loop keeps 60 Hz when
the window loses focus. `F11` toggles fullscreen at the OS level; the game's own
`F` key and its pause menu do the same from inside the page.

`disable-backgrounding-occluded-windows` is set because the Steam Deck and older
integrated GPUs otherwise throttle a fullscreen canvas app.

## Controls it inherits

Keyboard, mouse and **gamepad** all work — the game polls the standard Gamepad API
mapping, which is what both XInput and the Steam Deck present:

| Pad | Action |
| --- | --- |
| Left stick / D-pad | Move and aim (8-way) |
| **X** / RB / RT | Fire |
| **A** / LB / LT | Jump |
| **Start** / Back | Pause, and start from the title |

The pause menu (RESUME · RESTART STAGE · FULLSCREEN · QUIT TO TITLE) is navigable
with the stick, the d-pad or the keyboard.

## Not done yet

- **Steamworks integration.** Achievements, Cloud saves and the overlay all need a
  real App ID issued by Valve, plus the `steamworks.js` native module. None of that
  can be wired up until the app exists in Steamworks, so it is deliberately absent
  rather than stubbed.
Settings, key bindings and your best run now persist in `localStorage`, which
Electron keeps per-app on disk — so they survive a restart of the packaged build
without any extra wiring. Steam Cloud would still need the Steamworks SDK to sync
that between machines.
