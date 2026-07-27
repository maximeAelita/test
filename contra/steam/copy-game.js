// Pulls the game and its icons into the Electron package. The parent folder stays
// the source of truth; steam/game/ is a build product and is gitignored.
const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..');
const dst = path.join(__dirname, 'game');

fs.rmSync(dst, { recursive: true, force: true });
fs.mkdirSync(path.join(dst, 'icons'), { recursive: true });

fs.copyFileSync(path.join(src, 'index.html'), path.join(dst, 'index.html'));
fs.copyFileSync(path.join(src, 'manifest.json'), path.join(dst, 'manifest.json'));
for (const f of fs.readdirSync(path.join(src, 'icons'))) {
  if (f.endsWith('.png')) fs.copyFileSync(path.join(src, 'icons', f), path.join(dst, 'icons', f));
}
console.log('copied index.html + icons -> steam/game/');
