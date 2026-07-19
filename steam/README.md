# NEON ORBIT — Steam / desktop packaging

The game itself is the single file `../neon-orbit.html` — this folder wraps it in
Electron so it can ship on Steam as a normal Windows/Linux/macOS executable.
The game already carries the desktop feature set Steam players expect:
fullscreen (`F`), pause menu (`Esc`), mute (`M`), instant restart (`R`),
mouse + keyboard play, **gamepad support** (A = sling / confirm, Start = pause —
works on Steam Deck), high-DPI crisp rendering, and letterboxed widescreen
presentation.

## Run it as a desktop app

```bash
cd steam
npm install
npm start        # copies ../neon-orbit.html into game/ and launches Electron fullscreen
```

## Build a distributable

```bash
npm run dist     # outputs an unpacked win-x64 build under steam/dist/
```

(Change `build.win.target` in `package.json` to `nsis` for an installer, or add
`--linux`/`--mac` targets. Build on the target OS or in CI.)

## Shipping on Steam — checklist

1. **Steamworks account & app credit** — register at partner.steamgames.com,
   pay the app fee, create the App ID.
2. **Depot upload** — point a depot at the `dist/` output and push with
   `steamcmd` + an `app_build.vdf` (see Steamworks docs "Uploading to Steam").
   Set the launch option to the built executable.
3. **Steam overlay / achievements (optional)** — add
   [`steamworks.js`](https://github.com/ceifa/steamworks.js) to this package and
   call `init(<appid>)` from `main.js`. Achievements map naturally to height
   milestones and star counts.
4. **Steam Deck** — the game is gamepad-driven and renders at any aspect;
   verify with Proton or the native Linux build for the "Verified" review.
5. **Store assets** — capsule art, screenshots, and a trailer are required by
   the store review; capture screenshots at 2560×1600 with `F` fullscreen.

Nothing in this folder is required to play the game — `../neon-orbit.html`
remains fully standalone in a browser.
