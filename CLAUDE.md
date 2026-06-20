# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository is a single-file browser game: **NEON TANK** (Phase 4), a top-down
arena tank shooter with a neon aesthetic. The entire game — markup, CSS, and game
logic — lives in `index.html`. There is no build system, no package manager, no
dependencies, and no test suite.

## Running / Developing

- **Run it:** open `index.html` directly in a browser, or serve the directory
  (e.g. `python3 -m http.server`) and load it. There is nothing to compile or install.
- **No build, lint, or test commands exist.** Don't add tooling (npm, bundlers,
  frameworks) unless explicitly asked — the project is intentionally a single
  dependency-free file.
- **Audio requires a user gesture.** The `AudioContext` is resumed via `resumeAC()`
  on the first click/keypress/touch; sound won't play until the player interacts.
- **Persistence:** the high score is stored in `localStorage` under the key
  `neonTankHS4`. Clear it to reset "BEST". Note the `4` suffix tracks the game phase
  version — bump the key if save format changes so old saves don't corrupt new logic.

## Architecture

Everything is plain DOM + Canvas 2D + Web Audio, written as top-level functions and
mutable module-scoped state (no classes, no modules). The three layers are:

1. **DOM/CSS overlays** (top of `index.html`): the HUD (`#ui`), buff bar, on-screen
   touch controls (`#joyZone`, `#actionZone`), and full-screen panels that are toggled
   via `style.display` — `#overlay` (start/game-over), `#upgradeScreen`, `#pauseScreen`,
   `#cutsceneScreen`, `#bossBar`. Game UI text is updated imperatively in `updateUI()`
   and `updateBuffs()`; HTML is not data-bound, so changing displayed stats means
   editing those functions.
2. **The canvas game** drawn into `#gameCanvas`. The play field is a fixed 20×20 tile
   grid (`COLS`/`ROWS`); `TILE`, `W`, `H` (the canvas's *internal* resolution) are
   derived from viewport width at load and never change. Display sizing is separate:
   `fitStage()` sets the CSS size of the canvas/wrapper to fit the current viewport in
   either orientation, and re-runs on `resize`/`orientationchange`/`visualViewport`
   resize. Because the internal resolution is fixed, entity coordinates are never
   rescaled (no desync), and all input maps screen→game via the live
   `getBoundingClientRect()`/`offsetWidth`, so it stays correct under CSS scaling.
3. **Web Audio** via a single shared `AudioContext`; all SFX are synthesized inline in
   `snd(type)` (oscillators + a noise buffer for explosions). To add a sound, add a
   branch there and call `snd('yourtype')`.

### Game loop

`loop(ts)` (bottom of the script) runs continuously via `requestAnimationFrame` and is
the single driver. Each frame it computes a clamped `dt` (capped at 50ms to avoid
tunneling), then early-returns if `paused` or `cutsceneActive`; otherwise it calls
`update(dt)` → `draw()` → `updateUI()`. The loop is started once at load and again in
`startGame()`; the `running`/`paused`/`cutsceneActive` flags — not loop teardown —
gate whether simulation advances.

### State

State is a handful of module-scoped globals, not a single store:

- `state` — run-level: `score`, `kills`, `phase`, `bossNum`, `upgPoints`, plus
  `_lastUpgKill` (internal bookkeeping for awarding upgrade points every 5 kills).
- `player`, `boss`, plus the entity arrays `enemies`, `bullets`, `powerups`,
  `particles`, and the tile `map` (2D array of `T_EMPTY`/`T_BRICK`/`T_STEEL`/`T_WATER`).
- `upgrades` (persistent-per-run upgrade levels) and `currentSkin`.
- Flags: `bossPhase`, `paused`, `cutsceneActive`; input: `keys`, `mouseX/Y`, `joy`.

Entities are plain object literals created by factory functions (`createPlayer`,
`createEnemy`, `createBoss`) — there is no shared base type, so a field expected by
movement/collision/rendering (e.g. `w`, `h`, `angle`, `onWater`) must be set in the
factory. `moveEnt(e, dx, dy)` is the shared collision-resolved mover for all entities
(player, enemies, boss); `isSolid()` / `tileAt()` back it.

### Data-driven definitions

Game content is declared in top-level config arrays/objects, which is the place to edit
balance or add content:

- `SKINS` — player tank color variants.
- `UPG_DEFS` — upgrade types (id/name/max/cost); upgrade effects are applied where the
  matching `upgrades.<id>` is read (mostly inside `createPlayer`).
- `ENEMY_TYPES` — `standard`/`sniper`/`scout`/`heavy` stat blocks; spawn probabilities
  by phase live in `createEnemy`.
- `BOSS_DEFS` — 8 bosses, each with a `mechanic` string. **Boss behavior is a
  string-dispatch state machine:** the `mechanic` value (`shield`, `speed`, `invincible`,
  `invisible`, `split`, `artillery`, `summon`, `overlord`) is branched on in three
  places that must stay in sync — `updateBoss` (movement/timers), `bossShoot` (firing
  pattern), and `damageBoss` (which hits are valid, e.g. shield only breaks on SPECIAL).
  Adding a boss mechanic means adding branches in all three. `overlord` is a composite
  that cycles through the other mechanics via `overlordPhase`.

### Progression flow

Within a run: enemies spawn until `state.kills` hits the next multiple of 10, which
triggers `triggerBoss()` → `showCutscene()` → boss fight. Killing the boss
(`killBoss`) awards points, advances `state.phase`, and opens `showUpgradeScreen()`
before regenerating the map and continuing. Every 5 kills grants an upgrade point.
`gameOver()` saves the high score and shows the restart overlay.

### Input

Three parallel schemes feed the same state, all wired near the middle of the script:
keyboard (`keys` map + keydown handlers for special/ammo/pause), mouse (move = aim,
click = fire), and touch (left-half virtual joystick in `#joyZone`; right-half canvas
taps aim+fire; on-screen FIRE/SPEC/AMO/pause buttons). Touch handlers use
`{passive:false}` and `preventDefault()` to suppress scrolling/zoom, and have
`touchcancel` resets so the joystick/aim don't stick when iOS interrupts a touch.

`isTouch` (capability-based: `ontouchstart` / `maxTouchPoints` / `pointer:coarse`)
toggles a `touch`/`no-touch` class on `<body>`; the on-screen movement/fire controls
are hidden via CSS on `no-touch` (desktop) and shown on touch devices. Mobile-browser
behaviors that break a canvas game are suppressed globally: pinch-zoom
(`gesturestart`/`gesturechange`), double-tap zoom (300 ms `touchend` guard), the
long-press callout (`contextmenu` + `-webkit-touch-callout`), pull-to-refresh/overscroll
(`overscroll-behavior:none` + `position:fixed` body), and the notch via
`viewport-fit=cover` + `env(safe-area-inset-*)` padding. Audio is unlocked on the first
gesture through `resumeAC()` (iOS starts the `AudioContext` suspended).

## Conventions

- **Single file, no dependencies.** Keep additions inline in `index.html` unless asked
  to restructure.
- **Terse, dense style.** Existing code packs many statements per line with short names
  (`N` = neon palette, `T` = tile/type constants). Match the surrounding density rather
  than reformatting; large rewrites of working sections create noisy diffs.
- **Tuning constants are inline.** Speeds, cooldowns, damage, and spawn rates are
  literals scattered through the factories and `update`/`updateBoss`. When changing
  balance, search for the relevant entity factory or the `mechanic` branch.
- The branch for development work in this repo is `claude/claude-md-docs-vjhihh`.
