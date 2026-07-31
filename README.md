# Games

Three browser games, one folder each. No build step, no package manager, no
dependencies — every game is a single self-contained HTML file plus its install
metadata.

**Play them:** <https://maximeaelita.github.io/test/>

| Game | Folder | One-liner |
| --- | --- | --- |
| **NEON ORBIT** | [`neon-orbit/`](./neon-orbit) | One-thumb arcade climber — orbit planets, tap to sling, don't fall. Portrait, built for iPhone. |
| **NEON TANK** | [`neon-tank/`](./neon-tank) | Top-down arena tank shooter — destructible terrain, eight bosses, upgrades between phases. |
| **ECHO DUNGEON** | [`echo-dungeon/`](./echo-dungeon) | 3D puzzle RPG played mostly by ear. |

**IRONVINE** used to live here as `contra/`. It has moved to its own repository:
**<https://github.com/maximeAelita/ironvine>** — it is heading for a commercial
Steam release and needed its own name, issues and releases rather than sharing a
repo called `test`. Its full history came with it.

## Layout

Every game folder is self-contained and follows the same shape:

```
<game>/
  index.html      the entire game
  manifest.json   PWA metadata, start_url "./"
  icons/          home-screen icons
  steam/          Electron wrapper, where one exists
```

Nothing at the repo root belongs to a particular game any more. The root
[`index.html`](./index.html) is a hub that links to the three folders — it used to
redirect straight to NEON ORBIT, which is why NEON ORBIT's assets were sitting
loose at the root.

## Install on a phone home screen

Open the **game's own folder URL** in Safari — not the repo root — then
**Share → Add to Home Screen**:

- `https://maximeaelita.github.io/test/neon-orbit/`
- `https://maximeaelita.github.io/test/neon-tank/`
- `https://maximeaelita.github.io/test/echo-dungeon/`

Each folder carries its own `apple-touch-icon`, manifest, theme colour and
orientation lock, so each installs as a separate app with its own icon. On
Android/desktop Chrome the same URLs offer an **Install app** prompt.

> If you previously installed from `…/test/` you had NEON ORBIT, because the root
> redirected there. That shortcut now lands on the hub instead — remove it and
> re-add from `…/test/neon-orbit/`.

## Run locally

```bash
python3 -m http.server 8000
```

Then open <http://localhost:8000/>. Or just open any game's `index.html` in a
browser directly — none of them need a server.

## Desktop builds

[`neon-orbit/steam/`](./neon-orbit/steam) wraps NEON ORBIT in Electron for a
Windows build. `npm start` runs it, `npm run dist` packages it; `steam/game/` and
`steam/dist/` are build products and are gitignored.

NEON TANK and ECHO DUNGEON are browser-only.
