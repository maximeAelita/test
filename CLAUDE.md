# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## Overview

This repo holds **three unrelated browser games**, one folder each. They share no
code, no assets and no build system — treat each folder as its own project.

| Folder | Game | Notes |
| --- | --- | --- |
| `neon-orbit/` | NEON ORBIT | Portrait one-thumb climber. Has an Electron wrapper in `neon-orbit/steam/`. |
| `neon-tank/` | NEON TANK | Top-down arena shooter. See `neon-tank/CLAUDE.md` for its architecture. |
| `echo-dungeon/` | ECHO DUNGEON | 3D audio-led puzzle RPG. `offline.html` is a self-contained build. |

**IRONVINE is not here.** It used to be `contra/`; it now lives in its own repo,
<https://github.com/maximeAelita/ironvine>. Don't recreate it here.

## Working here

- **Identify the folder first.** A request about "the game" is ambiguous — ask or
  infer from the filename before editing. Nothing at the root belongs to a
  specific game.
- **Every game is one file.** `<game>/index.html` contains markup, CSS and all
  logic. No bundler, no package manager, no test suite. Don't add tooling unless
  asked.
- **No cross-folder edits.** A change to one game should never touch another.
- **Match the local style.** Each game has its own conventions and density; read
  the surrounding code rather than reformatting it.

## Folder shape

Each game folder is self-contained and installable on its own:

```
<game>/
  index.html      the entire game
  manifest.json   PWA metadata, start_url "./"
  icons/          home-screen icons, referenced as icons/…
  steam/          Electron wrapper, where one exists
```

Paths inside a game are **relative to its own folder**. When adding assets, keep
them inside the folder — anything at the repo root is shared infrastructure.

## Root files

- `index.html` — hub page linking to the three games. Not a game. It used to
  redirect to NEON ORBIT, which is why that game's assets were once loose at the
  root.
- `.gitignore` — Electron build products are matched as `**/steam/dist` and
  `**/steam/game` so the pattern works at any depth.
- `.gitattributes` — forces CRLF on `*.bat` / `*.cmd` so Windows helper scripts
  survive checkout regardless of the local `autocrlf` setting.

## Serving

```bash
python3 -m http.server 8000
```

Games also open fine from `file://` — none of them need a server.
