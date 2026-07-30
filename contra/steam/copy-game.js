// Pulls the game and its icons into the Electron package. The parent folder stays
// the source of truth; steam/game/ is a build product and is gitignored.
//
// Windows makes this less trivial than it looks. Deleting a directory there is not
// synchronous underneath — Explorer, the search indexer or AV can still hold a
// handle after rmSync returns, so recreating the same path immediately fails with
// EPERM. And a copy pulled out of a downloaded ZIP can arrive read-only, which makes
// copyFileSync over the top of it fail too. So: never wipe the tree, retry the
// transient failures, and clear the read-only bit before overwriting.
const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..');
const dst = path.join(__dirname, 'game');

const TRANSIENT = new Set(['EPERM', 'EBUSY', 'ENOTEMPTY', 'EACCES', 'EMFILE']);

// Synchronous sleep — this script runs before anything else and has no event loop
// worth yielding to, and Atomics.wait is the only honest way to block in Node.
function sleep(ms) { Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms); }

function retry(what, fn) {
  for (let i = 0; ; i++) {
    try { return fn(); }
    catch (e) {
      if (!TRANSIENT.has(e.code) || i >= 5) throw e;
      const wait = 100 * (1 << i);            // 100, 200, 400, 800, 1600 ms
      console.log(`  ${what}: ${e.code}, retrying in ${wait}ms`);
      sleep(wait);
    }
  }
}

function ensureDir(p) { retry('mkdir ' + path.basename(p), () => fs.mkdirSync(p, { recursive: true })); }

function copyOver(from, to) {
  retry('copy ' + path.basename(to), () => {
    // Drop a read-only destination out of the way first; copyFileSync will not
    // overwrite one, and ZIP extraction is a common way to end up with them.
    try { fs.chmodSync(to, 0o666); fs.unlinkSync(to); } catch (e) { if (e.code !== 'ENOENT') { /* fall through and let the copy report it */ } }
    fs.copyFileSync(from, to);
  });
}

ensureDir(dst);
ensureDir(path.join(dst, 'icons'));

copyOver(path.join(src, 'index.html'), path.join(dst, 'index.html'));
copyOver(path.join(src, 'manifest.json'), path.join(dst, 'manifest.json'));

const icons = fs.readdirSync(path.join(src, 'icons')).filter(f => f.endsWith('.png'));
for (const f of icons) copyOver(path.join(src, 'icons', f), path.join(dst, 'icons', f));

// Prune anything left over from an older build rather than wiping the tree.
const keep = new Set(['index.html', 'manifest.json', 'icons']);
for (const f of fs.readdirSync(dst)) {
  if (!keep.has(f)) retry('remove stale ' + f, () => fs.rmSync(path.join(dst, f), { recursive: true, force: true }));
}
const keepIcons = new Set(icons);
for (const f of fs.readdirSync(path.join(dst, 'icons'))) {
  if (!keepIcons.has(f)) retry('remove stale icon ' + f, () => fs.rmSync(path.join(dst, 'icons', f), { force: true }));
}

console.log(`copied index.html + manifest.json + ${icons.length} icons -> steam/game/`);
