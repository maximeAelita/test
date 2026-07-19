# Games in this repo

| Game | File | One-liner |
| --- | --- | --- |
| **NEON ORBIT** | [`neon-orbit.html`](./neon-orbit.html) | One-thumb iOS arcade climber — orbit planets, tap to sling, don't fall |
| **ECHO DUNGEON** | [`echo-dungeon.html`](./echo-dungeon.html) | 3D anime puzzle RPG played mostly by ear (below) |
| **NEON TANK** | [`index.html`](./index.html) | Top-down neon arena tank shooter with bosses and upgrades |

## NEON ORBIT

A portrait, one-thumb arcade game built for iPhone (works everywhere). Drift into a
planet's gravity and you orbit it; **tap to sling off along your tangent**. Gravity
arcs you back down, so chain slings from planet to planet to climb forever. Grab
&#9733; stars (+15 each), avoid the magenta **spiked planets**, and don't fall off
the bottom of the screen. High score persists in `localStorage`.

Open `neon-orbit.html` in any browser — or on iPhone, open it in Safari and use
**Share → Add to Home Screen** to play it fullscreen like a native app (it ships the
`apple-mobile-web-app` meta tags, safe-area padding, and zoom/scroll suppression).
Single self-contained file, zero dependencies.

**On PC** the game is desktop-grade: crisp high-DPI rendering, letterboxed
widescreen presentation, and gamepad support (A = sling, Start = pause — Steam
Deck friendly). Keys: click/`Space` sling · `Esc` pause · `R` restart ·
`M` sound · `F` fullscreen. The [`steam/`](./steam) folder wraps the game in
Electron with a build + Steamworks checklist for shipping it on Steam.

# ECHO DUNGEON

A 3D anime-styled **Puzzle RPG** that you play mostly by ear.

> The dungeon is completely dark. Every movement sends out a wave of sound that
> briefly reveals the walls, enemies and treasure around you. Between pulses there
> is only black — you navigate by **sound and memory**.

Single self-contained file: [`echo-dungeon.html`](./echo-dungeon.html). No build step.

> **Offline / on-device:** [`echo-dungeon-offline.html`](./echo-dungeon-offline.html) is the
> same game with Three.js inlined — one file, **no internet required**. Save it and open it
> in any browser (great for phones/tablets). `echo-dungeon.html` is the slim version that
> pulls Three.js from a CDN.

## Play

Open `echo-dungeon.html` in any modern browser, or serve the folder:

```bash
python3 -m http.server
# then visit http://localhost:8000/echo-dungeon.html
```

Audio (including the spatial enemy pings) unlocks on your first click/tap/keypress,
as browsers require.

### Controls

| Action | PC | Mobile |
| --- | --- | --- |
| Move | `W A S D` / arrow keys | left-side virtual joystick |
| Echo pulse | `Space` | **PULSE** button |
| Pause | `Esc` | — |

## The hook

* **Movement = light.** Walking emits small footstep waves; the **echo pulse** emits
  a big charged wave (with a cooldown). **Resonance plates** on the floor ring out a
  huge reveal when you step on them.
* **Enemies reveal themselves** by periodically pinging — those pings are *spatialised*
  (Web Audio HRTF), so you can literally hear which direction danger is coming from.
* Colour-coded reveals: walls (blue), the **sigil/key** (amber), **relics** (gold),
  the **exit portal** (green), enemies (red).

## Goal

Find the floating **sigil**, then reach the **exit portal** to descend to the next,
larger floor. Touching an enemy costs integrity. Collect relics along the way. Each
descent heals you a little — see how deep you can go.

## Tech

* **Three.js** (loaded from CDN via an import map) — no local dependencies.
* A single custom **echo shader** is shared by every surface (instanced walls + floor +
  actors). It accumulates light from up to 16 simultaneous expanding wavefronts, with
  cel/anime banding and a rim term; black back-face outlines give actors the toon look.
* **75% internal render scale** upscaled to the viewport, with a delta-timed loop
  targeting 60fps. Walls use an `InstancedMesh`; fully-buried wall cells are skipped.
* Keyboard, mouse and touch input; mobile zoom/scroll gestures are suppressed.
